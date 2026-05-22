#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.godot-mcp.env"
DEFAULT_OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"

echo "== Godot MCP OpenCode setup =="
echo

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing requirement: $cmd"
    exit 1
  fi
}

require_cmd node
require_cmd npm

if ! command -v opencode >/dev/null 2>&1; then
  echo "Warning: 'opencode' CLI was not found in PATH."
  echo "You can still continue, but OpenCode may not be available yet."
  echo
fi

if ! command -v godot >/dev/null 2>&1; then
  echo "Warning: 'godot' executable was not found in PATH."
  echo "If needed, provide a full Godot path below."
  echo
fi

echo "Godot Offline Documentation"
echo "  Download godot-docs-html-stable.zip from: https://docs.godotengine.org/en/stable/"
echo "  Unzip it, then provide the path to the folder containing index.html."
read -r -p "Path to Godot docs folder: " DOCS_DIR
if [[ -z "$DOCS_DIR" ]]; then
  echo "Documentation/project folder path is required."
  exit 1
fi

if [[ ! -d "$DOCS_DIR" ]]; then
  echo "Directory does not exist: $DOCS_DIR"
  exit 1
fi

read -r -p "Path to opencode.json [$DEFAULT_OPENCODE_CONFIG]: " OPENCODE_CONFIG
OPENCODE_CONFIG="${OPENCODE_CONFIG:-$DEFAULT_OPENCODE_CONFIG}"

echo "Godot Executable"
echo "  Enter the full path to the Godot executable, or a folder that contains it."
echo "  Accepted names: godot, godot.*, Godot_v*, *_console, etc."
read -r -p "  GODOT_PATH (leave blank to auto-detect): " GODOT_INPUT

if [[ -z "$GODOT_INPUT" ]]; then
  GODOT_PATH=""
  echo "  Will auto-detect Godot at runtime."
elif [[ -f "$GODOT_INPUT" ]]; then
  GODOT_PATH="$GODOT_INPUT"
  echo "  Using: $GODOT_PATH"
elif [[ -d "$GODOT_INPUT" ]]; then
  # Strip trailing slash so find works consistently
  GODOT_INPUT="${GODOT_INPUT%/}"
  echo "  Searching for Godot executables in: $GODOT_INPUT"
  mapfile -t CANDIDATES < <(find "$GODOT_INPUT" -maxdepth 1 -type f \( -name 'godot*' -o -name 'Godot*' \) | sort)
  if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
    echo "  No Godot executables found in that folder."
    read -r -p "  Full path to Godot executable (or blank to auto-detect): " GODOT_PATH
    if [[ -z "$GODOT_PATH" ]]; then
      echo "  Will auto-detect Godot at runtime."
    else
      echo "  Using: $GODOT_PATH"
    fi
  elif [[ ${#CANDIDATES[@]} -eq 1 ]]; then
    GODOT_PATH="${CANDIDATES[0]}"
    echo "  Found: $GODOT_PATH"
  else
    echo "  Multiple Godot executables found. Pick one:"
    for i in "${!CANDIDATES[@]}"; do
      echo "    [$((i+1))] $(basename "${CANDIDATES[$i]}")"
    done
    read -r -p "  Enter number: " CHOICE
    IDX=$((CHOICE - 1))
    if [[ $IDX -lt 0 || $IDX -ge ${#CANDIDATES[@]} ]]; then
      echo "Invalid selection."
      exit 1
    fi
    GODOT_PATH="${CANDIDATES[$IDX]}"
    echo "  Using: $GODOT_PATH"
  fi
else
  echo "  Warning: path not found; storing as-is."
  GODOT_PATH="$GODOT_INPUT"
fi

cat > "$ENV_FILE" <<EOF
DOCS_DIR="$DOCS_DIR"
GODOT_DOCS_PATH="$DOCS_DIR"
OPENCODE_CONFIG="$OPENCODE_CONFIG"
GODOT_PATH="$GODOT_PATH"
EOF

echo
echo "Saved environment config to: $ENV_FILE"
echo "Next steps:"
echo "  1) ./update_opencode.sh"
echo "  2) ./launch.sh"
