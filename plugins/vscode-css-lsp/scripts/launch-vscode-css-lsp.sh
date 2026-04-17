#!/usr/bin/env sh
set -eu

try() { command -v "$1" >/dev/null 2>&1; }

if try bunx; then
  exec bunx -p vscode-langservers-extracted vscode-css-language-server "$@"
fi
if try pnpm; then
  exec pnpm --package=vscode-langservers-extracted dlx vscode-css-language-server -- "$@"
fi
if try npx; then
  exec npx -y --package=vscode-langservers-extracted vscode-css-language-server -- "$@"
fi

cat >&2 <<EOF
error: none of bunx / pnpm / npx found on PATH
tried to launch: vscode-css-language-server (from vscode-langservers-extracted)
install one of:
  - https://bun.sh
  - https://pnpm.io
  - https://nodejs.org
EOF
exit 127
