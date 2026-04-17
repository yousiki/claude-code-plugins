# JS/TS Tool Plugin Template

Reference skeleton for plugins that launch an npm-distributed tool. Copy these files into a new `plugins/<name>/` directory and fill in the `<…>` placeholders.

## Files

- `plugin.json.example` → `plugins/<name>/.claude-plugin/plugin.json`
- `launch.sh.example` → `plugins/<name>/scripts/launch-<name>.sh` (mark executable)
- `marketplace-entry.example.json` → JSON fragment to paste into the root `.claude-plugin/marketplace.json` under `plugins`

## Runtime chain

The wrapper tries, in order:

1. `bunx` — https://bun.sh
2. `pnpm dlx` — https://pnpm.io
3. `npx -y` — bundled with Node.js

If none is available, the wrapper exits 127 with an actionable error listing each runtime's install URL.

## When to use this template

For tools distributed via npm, regardless of what source language they analyze. Examples:

- `typescript-language-server`, `pyright-langserver` (both npm-first)
- MCP servers published as npm packages (e.g. `@upstash/context7-mcp`)

For PyPI-distributed tools (ruff, basedpyright, ty) use `../python-tool-plugin/` instead.
