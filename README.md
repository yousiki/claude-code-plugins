# yousiki-language-tools

A curated Claude Code plugin marketplace focused on Python / TypeScript language tooling. Every plugin launches its underlying tool through a runtime fallback chain (bunx / pnpm dlx / npx for JS-TS, uvx / pipx run / python -m for Python), so you never need a host-level global install.

Design: see [docs/superpowers/specs/2026-04-17-marketplace-design.md](docs/superpowers/specs/2026-04-17-marketplace-design.md).

## Scope

| Plugin              | Kind   | Runtime chain | Status  |
| ------------------- | ------ | ------------- | ------- |
| `context7`          | MCP    | JS/TS         | planned |
| `typescript-lsp`    | LSP    | JS/TS         | planned |
| `pyright-lsp`       | LSP    | JS/TS         | planned |
| `basedpyright-lsp`  | LSP    | Python        | planned |
| `ty-lsp` (beta)     | LSP    | Python        | planned |
| `ruff-formatter`    | Hook   | Python        | planned |

## Install

Inside Claude Code:

```
/plugin marketplace add yousiki/claude-code-plugins
/plugin install <plugin-name>@yousiki-language-tools
```

Each plugin's README lists the runtimes it can use; at least one of the chain must be on your `PATH`.

## Repository layout

```
.
├── .claude-plugin/marketplace.json   # authoritative plugin list
├── plugins/<name>/                   # one folder per plugin
│   ├── .claude-plugin/plugin.json    # metadata only
│   ├── scripts/launch-<name>.sh      # runtime fallback wrapper
│   └── README.md
├── templates/                        # copy-paste references (not executable)
│   ├── js-ts-tool-plugin/
│   └── python-tool-plugin/
└── docs/superpowers/specs/           # design documents
```

## Contributing a new plugin

1. Decide the runtime chain based on how the tool is distributed (not what it analyzes). See the design doc's "Choose runtime by launcher ecosystem" section.
2. Copy the matching template into `plugins/<name>/` and fill in the marked sections.
3. Append a marketplace entry to `.claude-plugin/marketplace.json`.
4. Test the fallback chain on a machine with only one of the runtimes installed at a time.
