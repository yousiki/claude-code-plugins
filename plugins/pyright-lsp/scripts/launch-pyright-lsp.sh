#!/usr/bin/env sh
# Launch pyright-langserver with runtime fallback.
# The npm package name is `pyright`; the bin we want is `pyright-langserver`,
# so we use `-p pyright` to widen the install set.
set -eu

try() { command -v "$1" >/dev/null 2>&1; }

if try bunx; then
  exec bunx -p pyright pyright-langserver "$@"
fi
if try pnpm; then
  exec pnpm dlx -p pyright pyright-langserver -- "$@"
fi
if try npx; then
  exec npx -y -p pyright pyright-langserver -- "$@"
fi

cat >&2 <<EOF
error: none of bunx / pnpm / npx found on PATH
tried to launch: pyright-langserver $*
install one of:
  - https://bun.sh
  - https://pnpm.io
  - https://nodejs.org (ships npx)
EOF
exit 127
