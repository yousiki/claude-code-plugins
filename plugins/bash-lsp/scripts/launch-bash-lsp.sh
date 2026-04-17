#!/usr/bin/env sh
set -eu

try() { command -v "$1" >/dev/null 2>&1; }

if try bunx; then
  exec bunx bash-language-server "$@"
fi
if try pnpm; then
  exec pnpm dlx bash-language-server -- "$@"
fi
if try npx; then
  exec npx -y bash-language-server -- "$@"
fi

cat >&2 <<EOF
error: none of bunx / pnpm / npx found on PATH
tried to launch: bash-language-server $*
install one of:
  - https://bun.sh
  - https://pnpm.io
  - https://nodejs.org
EOF
exit 127
