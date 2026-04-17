#!/usr/bin/env sh
set -eu

try() { command -v "$1" >/dev/null 2>&1; }

if try bunx; then
  exec bunx -p @biomejs/biome biome "$@"
fi
if try pnpm; then
  exec pnpm --package=@biomejs/biome dlx biome -- "$@"
fi
if try npx; then
  exec npx -y --package=@biomejs/biome biome -- "$@"
fi

cat >&2 <<EOF
error: none of bunx / pnpm / npx found on PATH
tried to launch: biome (from @biomejs/biome) $*
install one of:
  - https://bun.sh
  - https://pnpm.io
  - https://nodejs.org
EOF
exit 127
