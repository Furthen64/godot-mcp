Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $ScriptDir ".godot-mcp.env"
$BuildEntry = Join-Path $ScriptDir "build/index.js"

if (Test-Path -LiteralPath $EnvFile) {
  Get-Content -LiteralPath $EnvFile | ForEach-Object {
    if ($_ -match '^\s*([A-Z0-9_]+)\s*=\s*"(.*)"\s*$') {
      Set-Variable -Name $matches[1] -Value $matches[2] -Scope Script
    }
  }
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "node is required" }
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw "npm is required" }

if (-not (Test-Path -LiteralPath $BuildEntry -PathType Leaf)) {
  Write-Host "Build not found. Running npm install and npm run build..."
  Push-Location $ScriptDir
  try { npm install; npm run build } finally { Pop-Location }
}

$env:DEBUG = if ($env:DEBUG) { $env:DEBUG } else { "true" }
if (Get-Variable -Name GODOT_PATH -Scope Script -ErrorAction SilentlyContinue) {
  if (-not [string]::IsNullOrWhiteSpace($script:GODOT_PATH)) {
    $env:GODOT_PATH = $script:GODOT_PATH
  }
}
if (-not $env:GODOT_DOCS_PATH) {
  if (Get-Variable -Name DOCS_DIR -Scope Script -ErrorAction SilentlyContinue) {
    if (-not [string]::IsNullOrWhiteSpace($script:DOCS_DIR)) {
      $env:GODOT_DOCS_PATH = $script:DOCS_DIR
    }
  }
}

Write-Host "Launching Godot MCP server..."
& node $BuildEntry
