#!/usr/bin/env sh
set -eu

try() { command -v "$1" >/dev/null 2>&1; }

if try uvx; then
  exec uvx tombi "$@"
fi
if try pipx; then
  exec pipx run tombi "$@"
fi

cat >&2 <<EOF
error: no supported Python runtime found on PATH
tried to launch: tombi $*
install one of:
  - https://docs.astral.sh/uv/
  - https://pipx.pypa.io/
EOF
exit 127
