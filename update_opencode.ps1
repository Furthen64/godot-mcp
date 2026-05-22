Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $ScriptDir ".godot-mcp.env"
$DefaultOpenCodeConfig = Join-Path $HOME ".config/opencode/opencode.json"
$ServerName = "godot"
$BuildEntry = Join-Path $ScriptDir "build/index.js"

function ConvertTo-Hashtable {
  param([Parameter(Mandatory = $true)] $Value)

  if ($null -eq $Value) { return $null }

  if ($Value -is [System.Collections.IDictionary]) {
    $result = @{}
    foreach ($key in $Value.Keys) {
      $result[$key] = ConvertTo-Hashtable -Value $Value[$key]
    }
    return $result
  }

  if ($Value -is [System.Management.Automation.PSCustomObject]) {
    $result = @{}
    foreach ($property in $Value.PSObject.Properties) {
      $result[$property.Name] = ConvertTo-Hashtable -Value $property.Value
    }
    return $result
  }

  if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
    $result = @()
    foreach ($item in $Value) {
      $result += ,(ConvertTo-Hashtable -Value $item)
    }
    return $result
  }

  return $Value
}

function Parse-JsonObject {
  param([Parameter(Mandatory = $true)][string]$Json)

  $convertFromJson = Get-Command ConvertFrom-Json
  $supportsDepth = $convertFromJson.Parameters.ContainsKey("Depth")
  $supportsAsHashtable = $convertFromJson.Parameters.ContainsKey("AsHashtable")

  if ($supportsDepth -and $supportsAsHashtable) {
    return ($Json | ConvertFrom-Json -Depth 100 -AsHashtable)
  }
  if ($supportsDepth) {
    return ConvertTo-Hashtable -Value ($Json | ConvertFrom-Json -Depth 100)
  }

  return ConvertTo-Hashtable -Value ($Json | ConvertFrom-Json)
}

if (Test-Path -LiteralPath $EnvFile) {
  Get-Content -LiteralPath $EnvFile | ForEach-Object {
    if ($_ -match '^\s*([A-Z0-9_]+)\s*=\s*"(.*)"\s*$') {
      Set-Variable -Name $matches[1] -Value $matches[2] -Scope Script
    }
  }
}

$OpenCodeConfig = if ($args.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($args[0])) {
  $args[0]
} elseif (Get-Variable -Name OPENCODE_CONFIG -Scope Script -ErrorAction SilentlyContinue) {
  $script:OPENCODE_CONFIG
} else {
  $DefaultOpenCodeConfig
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "node is required" }
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw "npm is required" }

$NodeModules = Join-Path $ScriptDir "node_modules"
if (-not (Test-Path -LiteralPath $NodeModules -PathType Container)) {
  Write-Host "Installing npm dependencies..."
  Push-Location $ScriptDir
  try { npm install } finally { Pop-Location }
}

if (-not (Test-Path -LiteralPath $BuildEntry -PathType Leaf)) {
  Write-Host "Building server..."
  Push-Location $ScriptDir
  try { npm run build } finally { Pop-Location }
}

$OpenCodeDir = Split-Path -Parent $OpenCodeConfig
if (-not [string]::IsNullOrWhiteSpace($OpenCodeDir)) {
  New-Item -ItemType Directory -Path $OpenCodeDir -Force | Out-Null
}

$configBackupDate = Get-Date -Format "yyMMdd"
$configBackupPath = "${OpenCodeConfig}_bak${configBackupDate}"
if (Test-Path -LiteralPath $OpenCodeConfig -PathType Leaf) {
  Copy-Item -LiteralPath $OpenCodeConfig -Destination $configBackupPath -Force
}

$config = @{}
if (Test-Path -LiteralPath $OpenCodeConfig -PathType Leaf) {
  $rawContent = Get-Content -LiteralPath $OpenCodeConfig -Raw
  $raw = if ($null -eq $rawContent) { "" } else { $rawContent.Trim() }
  if ($raw) {
    $parsed = Parse-JsonObject -Json $raw
    if ($parsed -is [hashtable]) { $config = $parsed }
  }
}

$environmentMap = @{ DEBUG = "true" }
if (Get-Variable -Name GODOT_PATH -Scope Script -ErrorAction SilentlyContinue) {
  if (-not [string]::IsNullOrWhiteSpace($script:GODOT_PATH)) {
    $environmentMap["GODOT_PATH"] = $script:GODOT_PATH
  }
}
if (Get-Variable -Name GODOT_DOCS_PATH -Scope Script -ErrorAction SilentlyContinue) {
  if (-not [string]::IsNullOrWhiteSpace($script:GODOT_DOCS_PATH)) {
    $environmentMap["GODOT_DOCS_PATH"] = $script:GODOT_DOCS_PATH
  }
} elseif (Get-Variable -Name DOCS_DIR -Scope Script -ErrorAction SilentlyContinue) {
  if (-not [string]::IsNullOrWhiteSpace($script:DOCS_DIR)) {
    $environmentMap["GODOT_DOCS_PATH"] = $script:DOCS_DIR
  }
}

$resolvedBuildEntry = (Resolve-Path -LiteralPath $BuildEntry).Path
$config["mcp"] = @{
  $ServerName = @{
  type = "local"
  enabled = $true
  command = @("node", $resolvedBuildEntry)
  env = $environmentMap
  }
}

$json = $config | ConvertTo-Json -Depth 100
Set-Content -LiteralPath $OpenCodeConfig -Value $json

Write-Host "Updated OpenCode MCP config: $OpenCodeConfig"
Write-Host "Server '$ServerName' now points to: $BuildEntry"
