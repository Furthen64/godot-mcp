#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.godot-mcp.env"
BUILD_ENTRY="$SCRIPT_DIR/build/index.js"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

command -v node >/dev/null 2>&1 || { echo "node is required"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm is required"; exit 1; }

if [[ ! -f "$BUILD_ENTRY" ]]; then
  echo "Build not found. Running npm install and npm run build..."
  (cd "$SCRIPT_DIR" && npm install && npm run build)
fi

export DEBUG="${DEBUG:-true}"
if [[ -n "${GODOT_PATH:-}" ]]; then
  export GODOT_PATH
fi
if [[ -z "${GODOT_DOCS_PATH:-}" && -n "${DOCS_DIR:-}" ]]; then
  GODOT_DOCS_PATH="$DOCS_DIR"
fi
if [[ -n "${GODOT_DOCS_PATH:-}" ]]; then
  export GODOT_DOCS_PATH
fi

echo "Launching Godot MCP server..."
exec node "$BUILD_ENTRY"
