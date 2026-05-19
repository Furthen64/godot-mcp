Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $ScriptDir ".godot-mcp.env"
$DefaultOpenCodeConfig = Join-Path $HOME ".config/opencode/opencode.json"

Write-Host "== Godot MCP OpenCode setup =="
Write-Host ""

function Require-Command {
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Missing requirement: $Name"
  }
}

Require-Command node
Require-Command npm

if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
  Write-Warning "'opencode' CLI was not found in PATH. You can continue, but OpenCode may not be available yet."
}

if (-not (Get-Command godot -ErrorAction SilentlyContinue)) {
  Write-Warning "'godot' executable was not found in PATH. You can provide GODOT_PATH below."
}

$DocsDir = Read-Host "Path to your Godot documentation/project folder"
if ([string]::IsNullOrWhiteSpace($DocsDir)) {
  throw "Documentation/project folder path is required."
}
if (-not (Test-Path -LiteralPath $DocsDir -PathType Container)) {
  throw "Directory does not exist: $DocsDir"
}

$OpenCodeConfig = Read-Host "Path to opencode.json [$DefaultOpenCodeConfig]"
if ([string]::IsNullOrWhiteSpace($OpenCodeConfig)) {
  $OpenCodeConfig = $DefaultOpenCodeConfig
}

$GodotPath = Read-Host "Optional GODOT_PATH override (leave blank to auto-detect)"

$lines = @(
  "DOCS_DIR=""$DocsDir""",
  "OPENCODE_CONFIG=""$OpenCodeConfig""",
  "GODOT_PATH=""$GodotPath"""
)
Set-Content -LiteralPath $EnvFile -Value $lines

Write-Host ""
Write-Host "Saved environment config to: $EnvFile"
Write-Host "Next steps:"
Write-Host "  1) ./update_opencode.ps1"
Write-Host "  2) ./launch.ps1"
