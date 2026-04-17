# biome-formatter

A PostToolUse hook that runs [`biome format --write`](https://biomejs.dev/formatter/) on every supported JavaScript, TypeScript, JSON, or JSONC file Claude touches via `Write`, `Edit`, or `MultiEdit`. Never blocks the turn when the runtime is missing; missing-runtime cases surface as warnings on stderr.

## Runtime

JS/TS chain, in order:

1. `bunx -p @biomejs/biome biome format --write …` — preferred, isolated
2. `pnpm --package=@biomejs/biome dlx biome -- format --write …` — fallback
3. `npx -y --package=@biomejs/biome biome format --write …` — fallback

Install one:

- https://bun.sh
- https://pnpm.io
- https://nodejs.org/ (ships `npx`)

If none is present, the hook logs a one-line skip warning and exits cleanly; the rest of the session continues.

## What it does

- After any `Write | Edit | MultiEdit`, the hook inspects the tool input.
- If the written file ends in `.js`, `.mjs`, `.cjs`, `.jsx`, `.ts`, `.mts`, `.cts`, `.tsx`, `.d.ts`, `.json`, or `.jsonc`, it runs Biome format in place.
- Any other extension exits silently.

## Coexistence

Supported installation modes:

- `biome-formatter` alone, as the monolith for all Biome-owned JS, TS, JSON, and JSONC files.
- Subset formatters alone, such as `biome-js-formatter` or `biome-json-formatter`, when you want narrower Biome ownership.
- Cross-tool subsets with disjoint extensions, such as `biome-js-formatter` plus `ruff-formatter`.

Unsupported modes:

- `biome-formatter` plus a same-tool subset such as `biome-js-formatter` or `biome-json-formatter`.
- Two formatter subsets that both claim the same extension.

Those unsupported combinations can race because PostToolUse hooks may run in parallel. The hook does not try to detect that race.

## Files

- `.claude-plugin/plugin.json` — plugin metadata.
- `scripts/biome-format-hook.sh` — POSIX sh hook script. Parses stdin JSON, extracts `tool_input.file_path`, runs the runtime fallback chain.

Runtime configuration (the `hooks` block) is declared at the marketplace level in the root `.claude-plugin/marketplace.json` entry for this plugin.

## Smoke testing

Write a deliberately misformatted `.ts` or `.jsonc` file through Claude, then verify the on-disk file is rewritten by Biome.
