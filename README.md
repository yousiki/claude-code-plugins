<div align="center">

# yousiki's Claude Code Plugins

**A personal, curated marketplace of [Claude Code](https://docs.claude.com/en/docs/claude-code) plugins.**

Language servers, MCP servers, hooks, and workflow helpers &mdash; each tool boots through a runtime fallback chain (`bunx` / `uvx` and friends), so nothing has to be installed globally on the host.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin%20marketplace-6B4FBB)](https://docs.claude.com/en/docs/claude-code)
[![Plugins](https://img.shields.io/badge/plugins-23-brightgreen)](#plugins)
[![Maintenance](https://img.shields.io/badge/status-active-success)](#)

[Install](#install) &nbsp;·&nbsp; [Plugins](#plugins) &nbsp;·&nbsp; [Design](#design) &nbsp;·&nbsp; [Layout](#repository-layout) &nbsp;·&nbsp; [Contributing](#contributing)

</div>

---

## Highlights

- **Zero host install.** Each plugin launches through a fallback chain &mdash; JS/TS via `bunx` → `pnpm dlx` → `npx`, Python via `uvx` → `pipx run`.
- **Always fresh.** Every invocation resolves the package on demand from the registry; no stale global binaries to babysit.
- **Heterogeneous.** LSPs, MCP servers, and hooks live side by side; slash commands and agents will land as I adopt them.
- **Self-contained.** One folder per plugin, metadata-only &mdash; no vendored binaries, no submodules.
- **Opinionated.** Only tools I personally use day to day; each one is battle-tested in my own workflow before shipping.

## Plugins

Grouped by [plugin kind](https://docs.claude.com/en/docs/claude-code/plugins). All plugins live under [`plugins/`](plugins/) and are registered in [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json).

### Language Servers

| Plugin | Language | Runtime chain | Notes |
| --- | --- | --- | --- |
| [`typescript-lsp`](plugins/typescript-lsp) | TypeScript, JavaScript | JS/TS | `typescript-language-server`, pulls the `typescript` peer dep fresh |
| [`pyright-lsp`](plugins/pyright-lsp) | Python | JS/TS | Microsoft Pyright (npm-distributed) |
| [`basedpyright-lsp`](plugins/basedpyright-lsp) | Python | Python | Stricter community fork of Pyright |
| [`ty-lsp`](plugins/ty-lsp) | Python _(beta)_ | Python | Astral's Rust-based type checker; pre-1.0, expect churn |
| [`biome-lsp`](plugins/biome-lsp) | JS, TS, JSON | JS/TS | Biome language server (lint + format diagnostics) |
| [`bash-lsp`](plugins/bash-lsp) | Bash, shell | JS/TS | `bash-language-server`; integrates with `shellcheck` when on `PATH` |
| [`yaml-lsp`](plugins/yaml-lsp) | YAML | JS/TS | Red Hat `yaml-language-server` |
| [`tombi-lsp`](plugins/tombi-lsp) | TOML | Python | `tombi` LSP (chose over Taplo &mdash; Taplo's npm pkg lacks the LSP subcommand) |
| [`vscode-html-lsp`](plugins/vscode-html-lsp) | HTML | JS/TS | `vscode-langservers-extracted` (HTML binary) |
| [`vscode-css-lsp`](plugins/vscode-css-lsp) | CSS, SCSS, LESS | JS/TS | `vscode-langservers-extracted` (CSS binary) |
| [`vscode-json-lsp`](plugins/vscode-json-lsp) | JSON, JSONC | JS/TS | `vscode-langservers-extracted` (JSON binary) |

### MCP Servers

| Plugin | Purpose | Runtime chain |
| --- | --- | --- |
| [`context7`](plugins/context7) | Up-to-date library documentation lookup (Upstash Context7) | JS/TS |

### Hooks &mdash; Formatters

Auto-format on `PostToolUse` of `Write` / `Edit` / `MultiEdit`. Subset variants exist so you can pick only the languages you want formatted.

| Plugin | Files formatted | Runtime chain |
| --- | --- | --- |
| [`ruff-formatter`](plugins/ruff-formatter) | `.py` | Python |
| [`biome-formatter`](plugins/biome-formatter) | `.js`, `.jsx`, `.ts`, `.tsx`, `.json`, `.jsonc` | JS/TS |
| [`biome-js-formatter`](plugins/biome-js-formatter) | `.js`, `.jsx`, `.ts`, `.tsx` | JS/TS |
| [`biome-json-formatter`](plugins/biome-json-formatter) | `.json`, `.jsonc` | JS/TS |
| [`prettier-formatter`](plugins/prettier-formatter) | All prettier-supported extensions | JS/TS |
| [`prettier-js-formatter`](plugins/prettier-js-formatter) | `.js`, `.jsx`, `.ts`, `.tsx` | JS/TS |
| [`prettier-json-formatter`](plugins/prettier-json-formatter) | `.json` | JS/TS |
| [`prettier-css-formatter`](plugins/prettier-css-formatter) | `.css`, `.scss`, `.less` | JS/TS |
| [`prettier-html-formatter`](plugins/prettier-html-formatter) | `.html`, `.htm` | JS/TS |
| [`prettier-markdown-formatter`](plugins/prettier-markdown-formatter) | `.md`, `.mdx` | JS/TS |
| [`prettier-yaml-formatter`](plugins/prettier-yaml-formatter) | `.yaml`, `.yml` | JS/TS |

> More plugins &mdash; slash commands, agents, additional MCP servers &mdash; will be added over time as I adopt them.

## Install

Inside Claude Code:

```text
/plugin marketplace add yousiki/claude-plugins
/plugin install <plugin-name>@yousiki-claude-plugins
```

For example, to grab the TypeScript language server and the Ruff formatter hook:

```text
/plugin install typescript-lsp@yousiki-claude-plugins
/plugin install ruff-formatter@yousiki-claude-plugins
```

Each plugin's folder lists the runtime candidates it probes &mdash; at least one of them has to be on your `PATH`. Recommended baseline: [`bun`](https://bun.sh) for the JS/TS chain and [`uv`](https://docs.astral.sh/uv/) for the Python chain.

## Design

Three rules every plugin follows:

1. **No global installs.** The launcher script probes a runtime chain and runs the tool on demand. Missing one runtime is fine; missing all of them fails loudly with a clear error.
2. **Fallback by _distribution_ ecosystem, not by _language_ ecosystem.** Pyright is a Python tool but ships on npm &mdash; so it routes through the JS/TS chain. Basedpyright ships on PyPI &mdash; so it uses the Python chain.
3. **Metadata-only plugin folders.** `plugin.json` wires the launcher path; the launcher resolves the binary. Nothing is vendored, nothing is pinned beyond the tool's own versioning.

Formatter hooks additionally follow a **graceful-miss** contract: if no runtime on the fallback chain is present, the hook exits `0` silently rather than blocking the write.

## Repository Layout

```
.
├── .claude-plugin/
│   └── marketplace.json          # authoritative plugin registry
├── plugins/
│   └── <name>/
│       ├── .claude-plugin/
│       │   └── plugin.json       # plugin metadata
│       ├── scripts/
│       │   └── launch-<name>.sh  # runtime fallback wrapper
│       └── README.md
├── templates/                    # copy-paste scaffolds (not executable)
│   ├── js-ts-tool-plugin/
│   ├── python-tool-plugin/
│   └── formatter-hook-plugin/
├── LICENSE
└── README.md
```

## Contributing

This marketplace is primarily for my own use, but the scaffolding is deliberately general &mdash; feel free to fork and adapt, or open an issue / PR if you spot something broken.

To add a new plugin:

1. **Pick the runtime chain** based on how the tool is _distributed_, not what it analyzes. Rule of thumb: if it ships on npm (like Pyright), use the JS/TS chain; if it ships on PyPI (like Basedpyright), use the Python chain.
2. **Copy the matching template** from [`templates/`](templates/) into `plugins/<name>/` and replace every `<placeholder>` with the concrete value. Formatter hooks start from [`templates/formatter-hook-plugin/`](templates/formatter-hook-plugin/).
3. **Register the plugin** by appending an entry to [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json).
4. **Verify the fallback chain** by unsetting each runtime in turn (`PATH` manipulation works) and confirming the launcher still succeeds with any single one present.

## License

[MIT](LICENSE) &copy; [yousiki](https://github.com/yousiki)
