# prettier-yaml-formatter

A PostToolUse hook that runs Prettier on YAML files Claude touches via `Write`, `Edit`, or `MultiEdit`.

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
- If the written file ends in `.yaml` or `.yml`, it runs `prettier --write -- <file>` in place.
- Any other extension exits silently.
- Prettier discovers project configuration and ignore files through its normal rules.

## Coexistence

Supported:

- `prettier-yaml-formatter` alone, or with other non-overlapping Prettier subsets.
- Subset plugins alone when you want selected languages without installing `prettier-formatter`.
- Cross-tool subsets with disjoint extensions, such as `biome-json-formatter` + `prettier-yaml-formatter`.

Unsupported:

- `prettier-formatter` plus `prettier-yaml-formatter`, because both hooks can write YAML files.
- Two formatter subsets covering the same extension.

The hook does not detect these races; uninstall one overlapping formatter instead.

## Files

- `.claude-plugin/plugin.json` - plugin metadata.
- `scripts/prettier-yaml-format-hook.sh` - POSIX sh hook script that parses stdin JSON and formats matching files.
- `README.md` - usage notes and coexistence rules.

Runtime configuration (the `hooks` block) belongs in the root `.claude-plugin/marketplace.json` entry.

## Smoke testing

Feed a hook event containing a matching `tool_input.file_path` into `scripts/prettier-yaml-format-hook.sh`.
The file should be rewritten by Prettier when one runtime is installed.
Out-of-scope files should produce no output and exit 0.
