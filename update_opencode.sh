#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.godot-mcp.env"
DEFAULT_OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
SERVER_NAME="godot"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

OPENCODE_CONFIG="${1:-${OPENCODE_CONFIG:-$DEFAULT_OPENCODE_CONFIG}}"
BUILD_ENTRY="$SCRIPT_DIR/build/index.js"
DOCS_PATH="${GODOT_DOCS_PATH:-${DOCS_DIR:-}}"

command -v node >/dev/null 2>&1 || { echo "node is required"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm is required"; exit 1; }

if [[ ! -d "$SCRIPT_DIR/node_modules" ]]; then
  echo "Installing npm dependencies..."
  (cd "$SCRIPT_DIR" && npm install)
fi

if [[ ! -f "$BUILD_ENTRY" ]]; then
  echo "Building server..."
  (cd "$SCRIPT_DIR" && npm run build)
fi

mkdir -p "$(dirname "$OPENCODE_CONFIG")"

node - "$OPENCODE_CONFIG" "$BUILD_ENTRY" "$SERVER_NAME" "${GODOT_PATH:-}" "$DOCS_PATH" <<'NODE'
const fs = require("fs");
const path = require("path");

const [configPath, buildEntry, serverName, godotPath, docsPath] = process.argv.slice(2);
let config = {};

if (fs.existsSync(configPath)) {
  const raw = fs.readFileSync(configPath, "utf8").trim();
  if (raw) {
    config = JSON.parse(raw);
  }
}

if (!config || typeof config !== "object" || Array.isArray(config)) {
  config = {};
}

if (!config.mcp || typeof config.mcp !== "object" || Array.isArray(config.mcp)) {
  config.mcp = {};
}

if (!config.mcp.servers || typeof config.mcp.servers !== "object" || Array.isArray(config.mcp.servers)) {
  config.mcp.servers = {};
}

const env = { DEBUG: "true" };
if (godotPath) env.GODOT_PATH = godotPath;
if (docsPath) env.GODOT_DOCS_PATH = docsPath;

config.mcp.servers[serverName] = {
  type: "local",
  command: "node",
  args: [path.resolve(buildEntry)],
  env,
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + "\n", "utf8");
NODE

echo "Updated OpenCode MCP config: $OPENCODE_CONFIG"
echo "Server '$SERVER_NAME' now points to: $BUILD_ENTRY"
