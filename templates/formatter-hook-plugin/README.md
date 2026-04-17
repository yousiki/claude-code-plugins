# Formatter Hook Plugin Template

Reference skeleton for plugins that format a file after Claude writes it. Copy these files into a new `plugins/<name>/` directory and fill in the `EDIT_ME` placeholders.

## Files

- `.claude-plugin/plugin.json.example` -> `plugins/<name>/.claude-plugin/plugin.json`
- `scripts/format-hook.sh.example` -> `plugins/<name>/scripts/<name>-format-hook.sh` (mark executable after copying)
- `marketplace-entry.example.json` -> JSON fragment to paste into the root `.claude-plugin/marketplace.json` under `plugins`

## When to use this template

Use this for PostToolUse format-on-write plugins: tools that should run after `Write`, `Edit`, or `MultiEdit` and rewrite the touched file in place. It is the formatter-hook counterpart to `../js-ts-tool-plugin/` and `../python-tool-plugin/`.

The template follows the marketplace's hook contract:

- **No global installs.** Tools are fetched fresh through `bunx` / `pnpm dlx` / `npx` (JS/TS) or `uvx` / `pipx run` (Python) on every invocation.
- **Graceful miss.** If no runtime on the fallback chain is available, the hook exits `0` with a stderr warning rather than blocking the write.
- **Disjoint extension scopes.** Each formatter owns only the extensions it can safely rewrite; scopes are whitelisted in the `case "$FILE"` block.

## What to customize

- Plugin name, description, homepage, and author in `plugin.json`.
- Extension whitelist in the `case "$FILE"` block. Each formatter should own only the extensions it can safely rewrite.
- Tool command and runtime chain. The JS/TS chain is enabled by default; switch to the commented Python chain for PyPI-distributed formatters.
- Warning prefix on the graceful-miss path so stderr clearly names the plugin.

## Coexistence

Keep formatter scopes disjoint. A monolith formatter and one of its same-tool subsets can both fire on the same file, and two subsets that claim the same extension can race. Document supported combinations in the plugin README.
