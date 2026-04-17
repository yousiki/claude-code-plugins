# ty-lsp

> **BETA.** [ty](https://github.com/astral-sh/ty) is Astral's new Rust-based Python type checker. It is pre-1.0 (`0.0.x`) and breaking changes ship between patch releases. Do not rely on stable behaviour. Pin a tested version in `scripts/launch-ty-lsp.sh` once you have one.

## Runtime

Python chain, in order:

1. `uvx --from ty ty server`
2. `pipx run --spec ty ty server`

The `server` subcommand starts the LSP. Unlike pyright-family servers, ty does **not** take a `--stdio` flag — stdio is the only / default transport, supplied by the `args: ["server"]` in the marketplace entry.

## Pinning a version

When you find a working `ty` version, edit `scripts/launch-ty-lsp.sh`:

```sh
PKG="ty==0.0.31"
```

`uvx --from "ty==X.Y.Z"` and `pipx run --spec "ty==X.Y.Z"` both honour the pin.

## When to pick it

- You want an early look at Astral's next-gen type checker.
- You accept the instability and are prepared to bump the pin / revert to basedpyright-lsp if a release breaks.

For stable day-to-day type-checking, use `basedpyright-lsp` or `pyright-lsp`.
