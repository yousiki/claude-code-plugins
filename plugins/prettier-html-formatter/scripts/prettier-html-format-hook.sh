#!/usr/bin/env sh
# PostToolUse hook: reformat HTML files after Write / Edit / MultiEdit.
# Contract:
#   - input: Claude Code hook event JSON on stdin.
#   - output: never blocks the turn. Exits 0 in all paths.
#     On out-of-scope files, silent. On missing runtimes, logs to stderr.
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

case "$FILE" in
  *.html | *.htm) ;;
  *) exit 0 ;;
esac

if try bunx; then exec bunx prettier --write -- "$FILE"; fi
if try pnpm; then exec pnpm dlx prettier -- --write -- "$FILE"; fi
if try npx;  then exec npx -y prettier --write -- "$FILE"; fi

echo "prettier-html-formatter: skipped ($FILE) — install bun (https://bun.sh), pnpm (https://pnpm.io), or Node.js (ships npx) to enable." >&2
exit 0
