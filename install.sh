#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID="codex-usage"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/plugins/$PLUGIN_ID"

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cp -a "$SOURCE_DIR"/. "$TARGET_DIR"/
rm -rf "$TARGET_DIR/.git" "$TARGET_DIR/tests" "$TARGET_DIR/.pytest_cache"

echo "Installed Codex Usage to $TARGET_DIR"
echo "Reload Noctalia, enable the plugin, and add Codex Usage to the bar."
