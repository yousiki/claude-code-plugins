# yaml-lsp

[`yaml-language-server`](https://github.com/redhat-developer/yaml-language-server) packaged for Claude Code with a no-global-install launcher.

## What it is

`yaml-lsp` provides language-server features for YAML files, including diagnostics, completion, hover, validation, and schema-aware editing where the upstream server supports them.

Use it for project configuration, CI workflows, deployment manifests, docker-compose files, and other YAML-heavy codebases.

## How it runs

JS/TS chain, in order:

1. `bunx yaml-language-server`
2. `pnpm dlx yaml-language-server`
3. `npx -y yaml-language-server`

At least one of bun / pnpm / node must be on `PATH`.

Claude Code passes the language-server startup arguments via the marketplace entry. The wrapper only selects the first available runtime and execs `yaml-language-server` with those arguments.

## Extensions

This plugin registers:

- `.yml`
- `.yaml`

Runtime configuration (the `lspServers` block) is declared at the marketplace level in the root `.claude-plugin/marketplace.json` entry for this plugin.

## Notes

- The upstream server includes a built-in schema catalog that covers common formats such as GitHub Actions, Kubernetes, and docker-compose.
- Schema fetches happen over the network by default. In air-gapped or restricted environments, those remote lookups may fail or add latency.
- If none of bunx, pnpm, or npx are available, the launcher exits 127 and prints install URLs for the supported runtimes.
