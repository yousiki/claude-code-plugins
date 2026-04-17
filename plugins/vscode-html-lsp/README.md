# vscode-html-lsp

[`vscode-html-language-server`](https://github.com/hrsh7th/vscode-langservers-extracted) packaged for Claude Code with a no-global-install launcher.

The server comes from `vscode-langservers-extracted`, the npm package that publishes the HTML, CSS, and JSON language servers extracted from VS Code. This plugin starts only the HTML binary.

## Scope

This plugin intentionally does not start the CSS or JSON servers. Install the matching plugin when those file types need language support.

## Runtime

JS/TS chain, in order:

1. `bunx -p vscode-langservers-extracted vscode-html-language-server`
2. `pnpm --package=vscode-langservers-extracted dlx vscode-html-language-server`
3. `npx -y --package=vscode-langservers-extracted vscode-html-language-server`

At least one of bun, pnpm, or node must be on `PATH`.

## Notes

- Claude Code starts the server with `--stdio`; the marketplace entry supplies that through `args`.
- This plugin registers `.html` and `.htm` files.
- Use this when you want HTML-specific validation and editor features without installing the full VS Code extension stack.
- The server is useful for plain HTML templates and generated static-site markup.
- The package also contains CSS and JSON language servers, but those are separate marketplace plugins so users can enable only the servers they want.
- Sharing the npm package is intentional; local runtime caches handle reuse.

## Manual Check

Enable the plugin, open an HTML file, and confirm Claude Code starts `vscode-html-language-server`. Completion, hover, document symbols, and diagnostics should come from the VS Code HTML server.
