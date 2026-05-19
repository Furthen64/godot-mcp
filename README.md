# Godot MCP

Repository: https://github.com/Furthen64/godot-mcp

Use these scripts in order to get the project running.

## Requirements

- Node.js 18+
- npm
- Godot installed locally
- OpenCode installed locally

## Script order

### 1) Clone and enter the repo

```bash
git clone https://github.com/Furthen64/godot-mcp.git
cd godot-mcp
```

### 2) Run setup

macOS/Linux:

```bash
./setup.sh
```

Windows PowerShell:

```powershell
.\setup.ps1
```

This installs dependencies, validates your environment, and writes local config to `.godot-mcp.env`.

### 3) Register/update MCP in OpenCode

macOS/Linux:

```bash
./update_opencode.sh
```

Windows PowerShell:

```powershell
.\update_opencode.ps1
```

This updates your OpenCode MCP server config to point at this repository's built server.

### 4) Launch manually (optional)

macOS/Linux:

```bash
./launch.sh
```

Windows PowerShell:

```powershell
.\launch.ps1
```

Use this only if you want to run the MCP server directly outside OpenCode.
