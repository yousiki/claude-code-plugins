# biome-lsp

[`@biomejs/biome`](https://biomejs.dev/) language server, packaged for Claude Code with a no-global-install launcher.

## What it is

`biome-lsp` provides Biome's language-server features for JavaScript, TypeScript, JSX, TSX, and JSON files where the upstream server supports them.

Use it when you want Biome diagnostics and editor intelligence available inside Claude Code without requiring a project-local or global Biome install.

## How it runs

JS/TS chain, in order:

1. `bunx -p @biomejs/biome biome`
2. `pnpm --package=@biomejs/biome dlx biome`
3. `npx -y --package=@biomejs/biome biome`

At least one of bun / pnpm / node must be on `PATH`.

Claude Code passes the language-server startup arguments via the marketplace entry. The wrapper only selects the first available runtime and execs `biome` with those arguments.

## Extensions

This plugin registers:

- JS family: `.js`, `.mjs`, `.cjs`, `.jsx`
- TS family: `.ts`, `.tsx`, `.mts`, `.cts`
- JSON family: `.json`, `.jsonc`
- CSS: `.css`
- GraphQL: `.graphql`, `.gql`

Runtime configuration (the `lspServers` block) is declared at the marketplace level in the root `.claude-plugin/marketplace.json` entry for this plugin.

## Notes

- `biome-lsp` overlaps with `typescript-lsp` for `.ts` and `.tsx` files.
- If both are enabled in the same project and diagnostics become noisy, disable one of the two per project.
- If none of bunx, pnpm, or npx are available, the launcher exits 127 and prints install URLs for the supported runtimes.
