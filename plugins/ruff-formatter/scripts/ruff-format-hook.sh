#!/usr/bin/env sh
# PostToolUse hook: reformat .py / .pyi files after Write / Edit / MultiEdit.
# Contract:
#   - input: Claude Code hook event JSON on stdin.
#   - output: never blocks the turn. Exits 0 in all paths.
#     On out-of-scope files, silent. On runtime errors, logs to stderr.
set -u

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
  *.py | *.pyi) ;;
  *) exit 0 ;;
esac

run_format() {
  if "$@" format "$FILE"; then
    return 0
  fi
  echo "ruff-formatter: ruff format failed on $FILE" >&2
}

if try uvx; then
  run_format uvx ruff
  exit 0
fi
if try pipx; then
  run_format pipx run ruff
  exit 0
fi

echo "ruff-formatter: skipped ($FILE) — install uv (https://docs.astral.sh/uv/) or pipx to enable." >&2
exit 0
