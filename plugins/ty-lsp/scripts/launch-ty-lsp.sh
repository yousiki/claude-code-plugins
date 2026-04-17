#!/usr/bin/env sh
# Launch ty server (Astral's Rust-based Python type checker LSP) with fallback.
# BETA: ty is pre-1.0. To pin a tested version, set e.g. PKG="ty==0.0.31".
set -eu

PKG="ty"   # edit to pin: e.g. "ty==0.0.31"

try() { command -v "$1" >/dev/null 2>&1; }

if try uvx; then
  exec uvx --from "$PKG" ty "$@"
fi
if try pipx; then
  exec pipx run --spec "$PKG" ty "$@"
fi

cat >&2 <<EOF
error: no supported Python runtime found on PATH
tried to launch: ty (from $PKG)
install one of:
  - https://docs.astral.sh/uv/ (provides uvx)
  - https://pipx.pypa.io/
EOF
exit 127
