#!/usr/bin/env sh
# PostToolUse hook: reformat JSON and JSONC files after Write / Edit / MultiEdit.
set -eu

try() { command -v "$1" >/dev/null 2>&1; }

# Prefer python3 for robust JSON parsing; fall back to a sed/grep pipeline.
extract_file_path() {
  if try python3; then
    python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print((d.get("tool_input") or {}).get("file_path") or "")
' 2>/dev/null
  else
    # Flatten newlines and grab the first file_path occurrence.
    tr '\n' ' ' \
      | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
      | head -1 \
      | sed 's/.*"\([^"]*\)"$/\1/'
  fi
}

FILE=$(extract_file_path || true)
[ -f "$FILE" ] || exit 0

case "$FILE" in
  *.json | *.jsonc) ;;
  *) exit 0 ;;
esac

if try bunx; then
  exec bunx -p @biomejs/biome biome format --write -- "$FILE"
fi
if try pnpm; then
  exec pnpm --package=@biomejs/biome dlx biome -- format --write -- "$FILE"
fi
if try npx; then
  exec npx -y --package=@biomejs/biome biome format --write -- "$FILE"
fi

echo "biome-json-formatter: skipped ($FILE) - install bun, pnpm, or Node.js/npm to enable." >&2
exit 0
