# prettier-formatter

A PostToolUse hook that runs Prettier on common JS, TS, JSON, CSS, HTML, Markdown, MDX, and YAML files Claude touches via `Write`, `Edit`, or `MultiEdit`.

## Runtime

JavaScript chain, in order:

1. `bunx prettier --write -- <file>` - preferred
2. `pnpm dlx prettier -- --write -- <file>` - fallback
3. `npx -y prettier --write -- <file>` - fallback

Install one:

- https://bun.sh
- https://pnpm.io
- https://nodejs.org

If none is present, the hook logs a one-line skip warning and exits cleanly.

## What it does

- After any `Write | Edit | MultiEdit`, the hook inspects the tool input.
- If the written file matches Prettier's listed core extensions, it runs `prettier --write -- <file>` in place.
- Any other extension exits silently.
- Prettier discovers project configuration and ignore files through its normal rules.

## Coexistence

Supported:

- `prettier-formatter` alone when Prettier should own every listed extension.
- Prettier subset plugins alone when you want only selected languages.
- Cross-tool subsets with disjoint extensions, such as `biome-json-formatter` + `prettier-yaml-formatter`.

Unsupported:

- `prettier-formatter` plus a Prettier subset, because both hooks can write the same file.
- Two formatter subsets covering the same extension, such as `biome-json-formatter` + `prettier-json-formatter`.

The hook does not detect these races; uninstall one overlapping formatter instead.

## Files

- `.claude-plugin/plugin.json` - plugin metadata.
- `scripts/prettier-format-hook.sh` - POSIX sh hook script that parses stdin JSON and formats matching files.
- `README.md` - usage notes and coexistence rules.

Runtime configuration (the `hooks` block) belongs in the root `.claude-plugin/marketplace.json` entry.

## Smoke testing

Feed a hook event containing a matching `tool_input.file_path` into `scripts/prettier-format-hook.sh`.
The file should be rewritten by Prettier when one runtime is installed.
Out-of-scope files should produce no output and exit 0.
