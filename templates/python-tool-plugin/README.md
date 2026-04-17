# Python Tool Plugin Template

Reference skeleton for plugins that launch a PyPI-distributed tool. Copy these files into a new `plugins/<name>/` directory and fill in the `<…>` placeholders.

## Files

- `plugin.json.example` → `plugins/<name>/.claude-plugin/plugin.json`
- `launch.sh.example` → `plugins/<name>/scripts/launch-<name>.sh` (mark executable)
- `marketplace-entry.example.json` → JSON fragment to paste into the root `.claude-plugin/marketplace.json` under `plugins`

## Runtime chain

The wrapper tries, in order:

1. `uvx` — https://docs.astral.sh/uv/
2. `pipx run` — https://pipx.pypa.io/
3. `python -m <module>` — only when the tool exposes a `__main__` entry (set `PY_MODULE`; leave blank to disable)

If none is available, the wrapper exits 127 with an actionable error.

## `--from` handling

When the PyPI package name differs from the console script name (e.g. `basedpyright` package, `basedpyright-langserver` script), `uvx` requires `--from`:

```
uvx --from basedpyright basedpyright-langserver --stdio
```

The template wrapper always passes `--from "$PKG"` so this works for both matching and differing names.

## When to use this template

For tools distributed on PyPI, regardless of implementation language. Examples:

- `ruff`, `ty` (Rust implementations, PyPI-distributed)
- `basedpyright` (Python / TypeScript mix, PyPI recommended)

For npm-distributed tools (pyright, typescript-language-server, npm-packaged MCP servers) use `../js-ts-tool-plugin/` instead.
