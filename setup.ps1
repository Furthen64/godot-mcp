Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $ScriptDir ".godot-mcp.env"
$DefaultOpenCodeConfig = Join-Path $HOME ".config/opencode/opencode.json"

function Write-Header {
  param([string]$Text)
  Write-Host ""
  Write-Host "--- $Text ---" -ForegroundColor Cyan
}

function Write-Step {
  param([string]$Text)
  Write-Host "  $Text" -ForegroundColor White
}

function Write-Ok {
  param([string]$Text)
  Write-Host "  [OK] $Text" -ForegroundColor Green
}

function Write-Warn {
  param([string]$Text)
  Write-Host "  [!]  $Text" -ForegroundColor Yellow
}

function Require-Command {
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Missing requirement: '$Name' was not found in PATH."
  }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  Godot MCP - OpenCode Setup   " -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

Write-Header "Checking requirements"
Require-Command node
Write-Ok "node found"
Require-Command npm
Write-Ok "npm found"

if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
  Write-Warn "'opencode' was not found in PATH. You can continue, but OpenCode may not be available yet."
} else {
  Write-Ok "opencode found"
}

if (-not (Get-Command godot -ErrorAction SilentlyContinue)) {
  Write-Warn "'godot' was not found in PATH. You can provide GODOT_PATH in the next step."
} else {
  Write-Ok "godot found"
}

Write-Header "Godot Offline Documentation"
Write-Step "Download godot-docs-html-stable.zip from: https://docs.godotengine.org/en/stable/"
Write-Step "Unzip it, then provide the path to the folder containing index.html."

$DocsDir = $null
while ($true) {
  Write-Host ""
  $DocsDir = Read-Host "  Path to Godot docs folder"
  if ([string]::IsNullOrWhiteSpace($DocsDir)) {
    throw "Documentation folder path is required."
  }
  if (-not (Test-Path -LiteralPath $DocsDir -PathType Container)) {
    Write-Warn "Directory does not exist: $DocsDir"
    continue
  }

  # Resolve the folder that actually contains index.html.
  # The user may have pointed at the parent of the extracted zip folder.
  Write-Host "  Searching for index.html..." -ForegroundColor White
  $IndexInRoot = Join-Path $DocsDir "index.html"
  if (Test-Path -LiteralPath $IndexInRoot -PathType Leaf) {
    Write-Ok "Found index.html in: $DocsDir"
    break
  }

  $MatchedDirs = @(Get-ChildItem -LiteralPath $DocsDir -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName "index.html") -PathType Leaf })
  if ($MatchedDirs.Count -eq 1) {
    $DocsDir = $MatchedDirs[0].FullName
    Write-Ok "Found index.html in subdirectory: $DocsDir"
    break
  } elseif ($MatchedDirs.Count -gt 1) {
    Write-Host ""
    Write-Host "  Multiple subdirectories contain an index.html. Pick one:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $MatchedDirs.Count; $i++) {
      Write-Host "    [$($i+1)] $($MatchedDirs[$i].FullName)" -ForegroundColor White
    }
    $Choice = Read-Host "  Enter number"
    $ChoiceIndex = [int]$Choice - 1
    if ($ChoiceIndex -lt 0 -or $ChoiceIndex -ge $MatchedDirs.Count) {
      throw "Invalid selection."
    }
    $DocsDir = $MatchedDirs[$ChoiceIndex].FullName
    Write-Ok "Using: $DocsDir"
    break
  } else {
    Write-Warn "Found no index.html in '$DocsDir' or any of its immediate subdirectories."
    $Retry = Read-Host "  Are you sure the path contains an index.html file? (Y to retry / N to abort)"
    if ($Retry -notmatch '^[Yy]') {
      throw "Aborted: no valid documentation folder selected."
    }
  }
}

Write-Header "OpenCode Configuration"
$OpenCodeConfig = Read-Host "  Path to opencode.json [default: $DefaultOpenCodeConfig]"
if ([string]::IsNullOrWhiteSpace($OpenCodeConfig)) {
  $OpenCodeConfig = $DefaultOpenCodeConfig
}
Write-Ok "Using: $OpenCodeConfig"

Write-Header "Godot Executable"
$GodotPath = Read-Host "  GODOT_PATH override (leave blank to auto-detect)"
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
  Write-Ok "Will auto-detect Godot at runtime."
} else {
  Write-Ok "Using: $GodotPath"
}

$lines = @(
  "DOCS_DIR=""$DocsDir""",
  "OPENCODE_CONFIG=""$OpenCodeConfig""",
  "GODOT_PATH=""$GodotPath"""
)
Set-Content -LiteralPath $EnvFile -Value $lines

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "  Setup complete!               " -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Config saved to: $EnvFile" -ForegroundColor White
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "    1) .\update_opencode.ps1" -ForegroundColor White
Write-Host "    2) .\launch.ps1" -ForegroundColor White
Write-Host ""
