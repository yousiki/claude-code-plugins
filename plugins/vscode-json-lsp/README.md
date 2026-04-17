# vscode-json-lsp

[`vscode-json-language-server`](https://github.com/hrsh7th/vscode-langservers-extracted) packaged for Claude Code with a no-global-install launcher.

The server comes from `vscode-langservers-extracted`, the npm package that publishes the HTML, CSS, and JSON language servers extracted from VS Code. This plugin starts only the JSON binary.

## Scope

This plugin intentionally does not start the HTML or CSS servers. Install the matching plugin when those file types need language support.

## Runtime

JS/TS chain, in order:

1. `bunx -p vscode-langservers-extracted vscode-json-language-server`
2. `pnpm --package=vscode-langservers-extracted dlx vscode-json-language-server`
3. `npx -y --package=vscode-langservers-extracted vscode-json-language-server`

At least one of bun, pnpm, or node must be on `PATH`.

## Notes

- Claude Code starts the server with `--stdio`; the marketplace entry supplies that through `args`.
- This plugin registers `.json` and `.jsonc` files.
- Use this when schema-backed completion is more important than formatter or linter behavior.
- The server is useful for `package.json`, `tsconfig.json`, and other common schema-backed JSON files.
- It overlaps with `biome-lsp` on `.json` and `.jsonc`. If double diagnostics or duplicate completions are noisy, disable one of the two plugins for that project.
- The package also contains HTML and CSS language servers, but those are separate marketplace plugins so users can enable only the servers they want.
- Sharing the npm package is intentional; local runtime caches handle reuse.

## Manual Check

Enable the plugin, open a JSON or JSONC file, and confirm Claude Code starts `vscode-json-language-server`. Schema-backed completion and diagnostics should come from the VS Code JSON server.
