#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_ROOT="${NOCTALIA_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}}"
TARGET_DIR="$DATA_ROOT/noctalia/plugins/codex-usage"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required." >&2
  exit 1
fi

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cp -a "$SOURCE_DIR"/. "$TARGET_DIR"/
rm -rf "$TARGET_DIR/.git" "$TARGET_DIR/tests" "$TARGET_DIR/.pytest_cache"
chmod +x "$TARGET_DIR/codex_usage.py"

if command -v noctalia >/dev/null 2>&1; then
  echo "Running Noctalia plugin lint..."
  noctalia plugins lint "$TARGET_DIR"
else
  echo "Warning: noctalia was not found in PATH; skipped plugin lint." >&2
fi

cat <<EOF
Installed Codex Usage for Noctalia v5 to:
  $TARGET_DIR

Next:
  1. Restart or reload Noctalia.
  2. Enable aaronroquefonseca/codex-usage in Plugins.
  3. Add the 'bar' widget to the desired bar section.

Optional helper test:
  python3 "$TARGET_DIR/codex_usage.py" --codex "$(command -v codex 2>/dev/null || printf codex)"
EOF