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
Write-Host ""
$DocsDir = Read-Host "  Path to Godot docs folder"
if ([string]::IsNullOrWhiteSpace($DocsDir)) {
  throw "Documentation folder path is required."
}
if (-not (Test-Path -LiteralPath $DocsDir -PathType Container)) {
  throw "Directory does not exist: $DocsDir"
}

# Resolve the folder that actually contains index.html.
# The user may have pointed at the parent of the extracted zip folder.
Write-Host "  Searching for index.html..." -ForegroundColor White
$IndexInRoot = Join-Path $DocsDir "index.html"
if (Test-Path -LiteralPath $IndexInRoot -PathType Leaf) {
  Write-Ok "Found index.html in: $DocsDir"
} else {
  $Matches = Get-ChildItem -LiteralPath $DocsDir -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName "index.html") -PathType Leaf }
  if ($Matches.Count -eq 1) {
    $DocsDir = $Matches[0].FullName
    Write-Ok "Found index.html in subdirectory: $DocsDir"
  } elseif ($Matches.Count -gt 1) {
    Write-Host ""
    Write-Host "  Multiple subdirectories contain an index.html. Pick one:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $Matches.Count; $i++) {
      Write-Host "    [$($i+1)] $($Matches[$i].FullName)" -ForegroundColor White
    }
    $Choice = Read-Host "  Enter number"
    $Index = [int]$Choice - 1
    if ($Index -lt 0 -or $Index -ge $Matches.Count) {
      throw "Invalid selection."
    }
    $DocsDir = $Matches[$Index].FullName
    Write-Ok "Using: $DocsDir"
  } else {
    throw "No index.html found in '$DocsDir' or any of its immediate subdirectories. Please check the path."
  }
}

Write-Header "OpenCode Configuration"
$OpenCodeConfig = Read-Host "  Path to opencode.json [default: $DefaultOpenCodeConfig]"
if ([string]::IsNullOrWhiteSpace($OpenCodeConfig)) {
  $OpenCodeConfig = $DefaultOpenCodeConfig
}
Write-Ok "Using: $OpenCodeConfig"

Write-Header "Godot Executable"
Write-Step "Enter the full path to the Godot executable, or a folder that contains it."
Write-Step "Accepted names: godot.exe, Godot_v*.exe, *_console.exe, etc."
$GodotInput = Read-Host "  GODOT_PATH (leave blank to auto-detect)"

if ([string]::IsNullOrWhiteSpace($GodotInput)) {
  $GodotPath = ""
  Write-Ok "Will auto-detect Godot at runtime."
} elseif (Test-Path -LiteralPath $GodotInput -PathType Leaf) {
  $GodotPath = $GodotInput
  Write-Ok "Using: $GodotPath"
} elseif (Test-Path -LiteralPath $GodotInput -PathType Container) {
  Write-Step "Searching for Godot executables in: $GodotInput"
  $Candidates = Get-ChildItem -LiteralPath $GodotInput -File |
    Where-Object { $_.Name -match '^[Gg]odot.*\.exe$' } |
    Sort-Object Name
  if ($Candidates.Count -eq 0) {
    Write-Warn "No Godot executables found in that folder."
    $GodotPath = Read-Host "  Full path to Godot executable (or blank to auto-detect)"
    if ([string]::IsNullOrWhiteSpace($GodotPath)) {
      Write-Ok "Will auto-detect Godot at runtime."
    } else {
      Write-Ok "Using: $GodotPath"
    }
  } elseif ($Candidates.Count -eq 1) {
    $GodotPath = $Candidates[0].FullName
    Write-Ok "Found: $GodotPath"
  } else {
    Write-Host ""
    Write-Host "  Multiple Godot executables found. Pick one:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $Candidates.Count; $i++) {
      Write-Host "    [$($i+1)] $($Candidates[$i].Name)" -ForegroundColor White
    }
    $Choice = Read-Host "  Enter number"
    $Index = [int]$Choice - 1
    if ($Index -lt 0 -or $Index -ge $Candidates.Count) {
      throw "Invalid selection."
    }
    $GodotPath = $Candidates[$Index].FullName
    Write-Ok "Using: $GodotPath"
  }
} else {
  Write-Warn "Path not found; storing as-is."
  $GodotPath = $GodotInput
  Write-Ok "Stored: $GodotPath"
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
