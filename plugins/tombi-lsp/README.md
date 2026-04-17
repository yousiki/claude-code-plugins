# tombi-lsp

[Tombi](https://github.com/tombi-toml/tombi) language server, packaged for Claude Code.

Tombi provides TOML diagnostics, completion, hover, and schema-aware editing without requiring a system Rust toolchain. It is distributed through PyPI, so this plugin launches it through the same Python runtime chain used by the Phase 1 Python tools.

## Why Tombi

Taplo is the TOML language server many users already know, but the npm `@taplo/cli` package does not ship the LSP. The Taplo language server is available from the native Rust binary built with LSP features, which is not a good fresh-exec dependency for this marketplace.

Tombi gives Claude Code TOML coverage without adding new launcher infrastructure.

## Runtime

Python chain, in order:

1. `uvx tombi`
2. `pipx run tombi`

At least one of `uvx` or `pipx` must be on `PATH`.

## Notes

- Claude Code starts the server with `lsp`; the marketplace entry supplies that through `args`.
- Tombi is schema-aware for common TOML files, including `pyproject.toml` and `Cargo.toml`.
- This plugin registers `.toml` files only.
- There is no `python -m` fallback because Tombi is launched through its console script.

## Manual Check

Enable the plugin, open a `pyproject.toml` or `Cargo.toml`, and confirm Claude Code starts the `tombi` server. You should see TOML diagnostics and schema-backed completion for known sections.
