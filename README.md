<div align="center">

# yousiki's Claude Plugins

**A personal marketplace of [Claude Code](https://docs.claude.com/en/docs/claude-code) plugins.**

Language servers, MCP servers, and formatter hooks &mdash; each tool is wrapped in a launcher that probes a runtime fallback chain (`bunx` / `uvx` and friends), so nothing has to be installed globally on the host.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin%20marketplace-6B4FBB)](https://docs.claude.com/en/docs/claude-code)
[![Plugins](https://img.shields.io/badge/plugins-25-brightgreen)](#plugins)
[![Maintenance](https://img.shields.io/badge/status-active-success)](#)

[Install](#install) &nbsp;·&nbsp; [Plugins](#plugins) &nbsp;·&nbsp; [Design](#design) &nbsp;·&nbsp; [Layout](#repository-layout) &nbsp;·&nbsp; [Contributing](#contributing)

</div>

---

## Highlights

- **No global installs required.** Each plugin launches through a runtime fallback chain &mdash; JS/TS via `bunx` → `pnpm dlx` → `npx`, Python via `uvx` → `pipx run`. You only need one runtime from each chain on `PATH`.
- **On-demand resolution.** Packages resolve from the registry at launch time, so there are no pinned global binaries to keep up to date.
- **Mixed plugin kinds.** LSPs, MCP servers, and formatter hooks live side by side; slash commands and agents may land later.
- **Metadata-only folders.** One folder per plugin &mdash; no vendored binaries, no submodules.
- **Personal scope.** These are the tools I reach for; expect the roster to drift as my own workflow changes.

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
| [`browseros`](plugins/browseros) | Drive the local [BrowserOS](https://www.browseros.com/) agentic browser (53 browser tools + 40+ app integrations) | Local HTTP |
| [`context7`](plugins/context7) | Up-to-date library documentation lookup (Upstash Context7) | JS/TS |
| [`deepwiki`](plugins/deepwiki) | AI-grounded Q&A over any public GitHub repo's wiki (Devin DeepWiki) | Remote HTTP |

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

> Additional plugin kinds (slash commands, agents, more MCP servers) may be added as I start using them.

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

Formatter hooks additionally follow a **graceful-miss** contract: if no runtime on the fallback chain is present, the hook exits `0` silently rather than blocking the write. This is intentional &mdash; a missing formatter shouldn't break the edit flow.

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

This marketplace is primarily for my own use, and I don't promise any particular support level &mdash; but the scaffolding is deliberately general, so feel free to fork and adapt, or open an issue / PR if you spot something broken.

To add a new plugin:

1. **Pick the runtime chain** based on how the tool is _distributed_, not what it analyzes. Rule of thumb: if it ships on npm (like Pyright), use the JS/TS chain; if it ships on PyPI (like Basedpyright), use the Python chain.
2. **Copy the matching template** from [`templates/`](templates/) into `plugins/<name>/` and replace every `<placeholder>` with the concrete value. Formatter hooks start from [`templates/formatter-hook-plugin/`](templates/formatter-hook-plugin/).
3. **Register the plugin** by appending an entry to [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json).
4. **Sanity-check the launcher** by invoking it directly &mdash; and, if you want to confirm the fallback works, try unsetting each runtime in turn (`PATH` manipulation works) and check the launcher still resolves with any single one present.

## License

[MIT](LICENSE) &copy; [yousiki](https://github.com/yousiki)
