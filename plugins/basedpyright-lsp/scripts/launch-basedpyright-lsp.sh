#!/usr/bin/env sh
# Launch basedpyright-langserver with runtime fallback.
# PyPI package name is `basedpyright`; bin is `basedpyright-langserver`,
# so uvx/pipx need an explicit "--from"/"--spec" to find the bin.
set -eu

try() { command -v "$1" >/dev/null 2>&1; }

if try uvx; then
  exec uvx --from basedpyright basedpyright-langserver "$@"
fi
if try pipx; then
  exec pipx run --spec basedpyright basedpyright-langserver "$@"
fi

cat >&2 <<EOF
error: no supported Python runtime found on PATH
tried to launch: basedpyright-langserver (from basedpyright)
install one of:
  - https://docs.astral.sh/uv/ (provides uvx)
  - https://pipx.pypa.io/
EOF
exit 127
