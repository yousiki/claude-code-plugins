#!/usr/bin/env sh
# Launch Upstash Context7 MCP server with runtime fallback.
set -eu

PKG="@upstash/context7-mcp"

try() { command -v "$1" >/dev/null 2>&1; }

if try bunx; then
  exec bunx "$PKG" "$@"
fi
if try pnpm; then
  exec pnpm dlx "$PKG" -- "$@"
fi
if try npx; then
  exec npx -y "$PKG" -- "$@"
fi

cat >&2 <<EOF
error: none of bunx / pnpm / npx found on PATH
tried to launch: $PKG $*
install one of:
  - https://bun.sh
  - https://pnpm.io
  - https://nodejs.org (ships npx)
EOF
exit 127
