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

read -r -p "Path to your Godot documentation/project folder: " DOCS_DIR
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

read -r -p "Optional GODOT_PATH override (leave blank to auto-detect): " GODOT_PATH

cat > "$ENV_FILE" <<EOF
DOCS_DIR="$DOCS_DIR"
OPENCODE_CONFIG="$OPENCODE_CONFIG"
GODOT_PATH="$GODOT_PATH"
EOF

echo
echo "Saved environment config to: $ENV_FILE"
echo "Next steps:"
echo "  1) ./update_opencode.sh"
echo "  2) ./launch.sh"
