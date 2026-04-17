# pyright-lsp

Microsoft [Pyright](https://github.com/microsoft/pyright) language server, packaged for Claude Code with a no-global-install launcher.

## Why the JS/TS chain for a Python tool?

Pyright is distributed primarily on npm; the PyPI `pyright` package is a thin bootstrap that downloads the npm release at runtime. Running it through `bunx` directly is faster and more predictable than going through PyPI. The plugin's runtime chain follows the launcher ecosystem of the tool, not the language it analyzes.

If you want a PyPI-first experience, use `basedpyright-lsp` instead.

## Runtime

JS/TS chain, in order:

1. `bunx -p pyright pyright-langserver`
2. `pnpm dlx -p pyright pyright-langserver`
3. `npx -y -p pyright pyright-langserver`

## Notes

- Bin name differs from package name (`pyright` package ships `pyright` and `pyright-langserver` bins); `-p pyright` tells bunx/pnpm/npx which package to install before running the named bin.
- Claude Code passes `--stdio` via the marketplace entry's `args` field.
