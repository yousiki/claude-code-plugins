# bash-lsp

[`bash-language-server`](https://github.com/bash-lsp/bash-language-server) packaged for Claude Code with a no-global-install launcher.

## What it is

`bash-lsp` provides language-server features for shell scripts, including diagnostics, completion, hover, and document symbols where the upstream server supports them.

Use it when a project contains shell entrypoints, maintenance scripts, install scripts, or CI helper scripts that Claude Code should understand as shell code.

## How it runs

JS/TS chain, in order:

1. `bunx bash-language-server`
2. `pnpm dlx bash-language-server`
3. `npx -y bash-language-server`

At least one of bun / pnpm / node must be on `PATH`.

Claude Code passes the language-server startup arguments via the marketplace entry. The wrapper only selects the first available runtime and execs `bash-language-server` with those arguments.

## Extensions

This plugin registers:

- `.sh`
- `.bash`

Runtime configuration (the `lspServers` block) is declared at the marketplace level in the root `.claude-plugin/marketplace.json` entry for this plugin.

## Notes

- `bash-language-server` integrates with `shellcheck` when `shellcheck` is already installed and visible on `PATH`.
- This plugin does not install `shellcheck`; diagnostic quality depends on the tools available on the host system.
- If none of bunx, pnpm, or npx are available, the launcher exits 127 and prints install URLs for the supported runtimes.
