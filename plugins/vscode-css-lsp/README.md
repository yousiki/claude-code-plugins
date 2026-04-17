# vscode-css-lsp

[`vscode-css-language-server`](https://github.com/hrsh7th/vscode-langservers-extracted) packaged for Claude Code with a no-global-install launcher.

The server comes from `vscode-langservers-extracted`, the npm package that publishes the HTML, CSS, and JSON language servers extracted from VS Code. This plugin starts only the CSS binary.

## Scope

This plugin intentionally does not start the HTML or JSON servers. Install the matching plugin when those file types need language support.

## Runtime

JS/TS chain, in order:

1. `bunx -p vscode-langservers-extracted vscode-css-language-server`
2. `pnpm --package=vscode-langservers-extracted dlx vscode-css-language-server`
3. `npx -y --package=vscode-langservers-extracted vscode-css-language-server`

At least one of bun, pnpm, or node must be on `PATH`.

## Notes

- Claude Code starts the server with `--stdio`; the marketplace entry supplies that through `args`.
- This plugin registers `.css`, `.scss`, and `.less` files.
- Use this when you want stylesheet validation and completion without a project-local language server install.
- The server is useful for design tokens, nested SCSS, Less variables, and plain CSS files.
- The package also contains HTML and JSON language servers, but those are separate marketplace plugins so users can enable only the servers they want.
- Sharing the npm package is intentional; local runtime caches handle reuse.

## Manual Check

Enable the plugin, open a CSS, SCSS, or Less file, and confirm Claude Code starts `vscode-css-language-server`. Completion, hover, document colors, and diagnostics should come from the VS Code CSS server.
