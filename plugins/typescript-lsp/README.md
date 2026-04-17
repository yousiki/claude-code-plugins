# typescript-lsp

[`typescript-language-server`](https://github.com/typescript-language-server/typescript-language-server) packaged for Claude Code with a no-global-install launcher.

Upstream's `plugins/typescript-lsp` assumes you've run `npm install -g typescript-language-server typescript`. This version pulls both packages fresh through `bunx` (or `pnpm dlx` / `npx`) on each launch.

## Runtime

JS/TS chain, in order:

1. `bunx -p typescript -p typescript-language-server typescript-language-server`
2. `pnpm dlx -p typescript -p typescript-language-server typescript-language-server`
3. `npx -y -p typescript -p typescript-language-server typescript-language-server`

At least one of bun / pnpm / node must be on `PATH`.

## Notes

- The wrapper always pulls a fresh `typescript`. If your project has a specific TypeScript version pinned in `node_modules`, this may diverge. See the design doc's Open Question 5 for the trade-off; revisit if it bites.
- Language server starts with `--stdio`; Claude Code supplies that via the `args` field in the marketplace entry.
