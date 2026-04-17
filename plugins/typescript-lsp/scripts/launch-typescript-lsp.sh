#!/usr/bin/env sh
# Launch typescript-language-server with runtime fallback.
# Pulls `typescript` alongside because the language server treats it as a peer
# dep and upstream's install instructions are "npm install -g … typescript".
set -eu

try() { command -v "$1" >/dev/null 2>&1; }

if try bunx; then
  exec bunx -p typescript -p typescript-language-server \
    typescript-language-server "$@"
fi
if try pnpm; then
  exec pnpm dlx -p typescript -p typescript-language-server \
    typescript-language-server -- "$@"
fi
if try npx; then
  exec npx -y -p typescript -p typescript-language-server \
    typescript-language-server -- "$@"
fi

cat >&2 <<EOF
error: none of bunx / pnpm / npx found on PATH
tried to launch: typescript-language-server $*
install one of:
  - https://bun.sh
  - https://pnpm.io
  - https://nodejs.org (ships npx)
EOF
exit 127
