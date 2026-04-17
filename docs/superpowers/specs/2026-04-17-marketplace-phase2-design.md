# Marketplace Phase 2 Design — Config/Web LSPs & Per-Language Formatters

Companion to [2026-04-17-marketplace-design.md](2026-04-17-marketplace-design.md). Phase 1 (context7 + Python/TS LSPs + ruff) is in implementation; this document specifies the **second batch** of plugins, to be built only after Phase 1's JS/TS chain launcher and hook contract are proven end-to-end.

This is a full rewrite of the prior Phase 2 draft. Scope and several design decisions changed based on research into Taplo's npm distribution, vscode-langservers-extracted's multi-binary shape, and how Biome/Prettier handle per-file scope.

## Goal

Extend the marketplace to cover:

- **Configuration-file and shell languages** used by JS/TS/Python projects — JSON, HTML, CSS, YAML, TOML, Bash.
- **Per-language formatter hooks** over the JS/TS/Python file families most projects touch — split into monolith + per-language-subset so users can both one-click-install ("give me everything Biome does") and mix-and-match ("Biome for JSON, Prettier for everything else").

All Phase 2 plugins run through the **existing JS/TS chain** (`bunx` → `pnpm dlx` → `npx`) or **Python chain** (`uvx` → `pipx`) defined in the v2 spec. No new chains; where the shared launcher cannot handle a plugin, it gets a bespoke wrapper on the Phase 1 pyright precedent.

## Relationship to Phase 1

Phase 2 inherits wholesale from the v2 spec:

- JS/TS chain launcher contract (v2 §"JS/TS chain") — used by single-binary npm packages.
- Python chain launcher contract (v2 §"Python chain") — used by `tombi-lsp`.
- PostToolUse hook contract (v2 §`ruff-formatter`) — stdin JSON parsing, path extraction, graceful-miss semantics, extension-whitelist early-exit.
- Manifest split: `marketplace.json` carries runtime (`lspServers` / `hooks`); per-plugin `plugin.json` is metadata only.
- Failure handling: exit 127 with actionable stderr when no runtime available; exit 0 silently on out-of-scope extensions.

Phase 2 does **not** start until Phase 1 validates the JS/TS launcher on at least one plugin (likely `context7`), the Python launcher on at least one plugin (likely `basedpyright-lsp`), and the hook contract on `ruff-formatter`. If any of those contracts changes during Phase 1 implementation, Phase 2 must be re-reviewed.

## Out of scope (explicit)

- **Nix tooling** — host has no `nix`; defer.
- **Rust tooling** — rust-analyzer/rustfmt are rustup-coupled and break fresh-exec.
- **C++/CUDA tooling** — LLVM-coupled; same reason.
- **Biome experimental languages** — HTML, Vue, Svelte, Astro are opt-in behind `html.experimentalFullSupportEnabled` as of Biome v2.4 and not production-ready.
- **Prettier plugin ecosystem** — TOML, XML, PHP, shell, Solidity, Java, etc. all require separate `prettier-plugin-*` npm packages whose wrapper shape differs from core. Defer to a future phase.
- **Niche languages** — Vue, Handlebars, MJML, Angular override, LWC, Flow, GraphQL standalone — low usage; add on-demand later.
- **Taplo LSP** — `@taplo/cli` npm package does not ship the language server (per Taplo's official docs). Replaced with `tombi-lsp` for TOML coverage.

Revisit any of these if the host gains the relevant toolchain or users specifically ask.

## Full plugin list (17 plugins)

### LSPs (7)

| Plugin | Chain | Package | Binary / subcommand | Languages |
|---|---|---|---|---|
| `biome-lsp` | JS/TS | `@biomejs/biome` | `biome lsp-proxy` | JS, TS, JSX, TSX, JSON, JSONC, CSS, GraphQL |
| `tombi-lsp` | Python | `tombi` (PyPI) | `tombi lsp` | TOML |
| `yaml-lsp` | JS/TS | `yaml-language-server` | `yaml-language-server --stdio` | YAML |
| `vscode-html-lsp` | JS/TS (bespoke) | `vscode-langservers-extracted` | `vscode-html-language-server --stdio` | HTML |
| `vscode-css-lsp` | JS/TS (bespoke) | `vscode-langservers-extracted` | `vscode-css-language-server --stdio` | CSS, SCSS, Less |
| `vscode-json-lsp` | JS/TS (bespoke) | `vscode-langservers-extracted` | `vscode-json-language-server --stdio` | JSON, JSONC |
| `bash-lsp` | JS/TS | `bash-language-server` | `bash-language-server start` | Bash, shell |

### Formatters (10)

**Biome family (3)** — covers Biome's most-used stable formatters (JS/TS/JSON). Biome also stably formats CSS and GraphQL, but those are deliberately excluded here as lower-usage; users who need them should use `prettier-css-formatter` / reach for a dedicated GraphQL tool, or request a future subset:

| Plugin | Extension whitelist |
|---|---|
| `biome-formatter` (monolith) | `.js .mjs .cjs .jsx .ts .mts .cts .tsx .d.ts .json .jsonc` |
| `biome-js-formatter` | `.js .mjs .cjs .jsx .ts .mts .cts .tsx .d.ts` |
| `biome-json-formatter` | `.json .jsonc` |

The monolith whitelist is exactly the union of the subsets — so "install monolith" and "install all subsets" are functionally equivalent (except the parallel-write race makes the latter an error; see §"Formatter coexistence rules").

**Prettier family (7)** — covers Prettier's most-used core formatters:

| Plugin | Extension whitelist |
|---|---|
| `prettier-formatter` (monolith) | all of the below unioned |
| `prettier-js-formatter` | `.js .mjs .cjs .jsx .ts .mts .cts .tsx` |
| `prettier-json-formatter` | `.json .json5 .jsonc` |
| `prettier-css-formatter` | `.css .scss .less` |
| `prettier-html-formatter` | `.html .htm` |
| `prettier-markdown-formatter` | `.md .markdown .mdx` |
| `prettier-yaml-formatter` | `.yaml .yml` |

## Design decisions

### Why `tombi-lsp` instead of `taplo-lsp`

The Codex review and a follow-up investigation confirmed: the `@taplo/cli` npm package explicitly does not include the language server. Per Taplo's own docs, `taplo lsp stdio` only exists in the native Rust binary built with `--features lsp`. Options for a Taplo LSP plugin were:

1. `cargo install taplo-cli --features lsp` — requires full Rust toolchain; not fresh-exec friendly.
2. GitHub releases binary download + plugin-dir cache — viable but requires new platform-detection infrastructure.
3. **`tombi`** — a Rust TOML LSP distributed as PyPI wheels with a maturin-built binary. Positions itself as a Taplo alternative, is actively maintained, schema-aware, and Helix ships it as the default TOML LSP with `command: "tombi", args: ["lsp"]`.

Option 3 requires zero new infrastructure — it plugs straight into the existing Python chain (`uvx tombi lsp`). Choose tombi now; option 2 can be added later as `taplo-lsp` if a user specifically needs Taplo's features.

### Why `vscode-lsp` is split into three plugins with bespoke wrappers

The `vscode-langservers-extracted` npm package ships three separate binaries:

- `vscode-html-language-server`
- `vscode-css-language-server`
- `vscode-json-language-server`

The v2 shared JS/TS launcher does `bunx "$PKG" "$@"` with `$PKG` as the npm package name. This works when **package name equals binary name** (bash, yaml, biome). For multi-binary packages, you must use `bunx -p PACKAGE BIN ...` to disambiguate. Phase 1 already has this precedent: pyright uses `bunx -p pyright pyright-langserver` because its binary name (`pyright-langserver`) differs from the package (`pyright`).

Two design implications:

1. **Three independent plugins, not one plugin with three `lspServers` entries.** This lets users install only the LSPs they want; unused servers aren't spawned. `bunx` caches by package, so all three plugins sharing `vscode-langservers-extracted` only pull the package once locally.
2. **Each plugin's wrapper is bespoke** — it follows the pyright pattern (`bunx -p vscode-langservers-extracted <binary> "$@"`) and does not delegate to the shared launcher. The fallback chain (bunx → pnpm dlx → npx) is re-expanded in each wrapper.

### Why formatters are split into monolith + per-language subsets

Investigation of Biome and Prettier configuration behavior surfaced three facts:

1. Both tools **default-format** with no project config. There is no `--require-config` flag in either tool, so installing a monolith formatter in a project with no config means every write gets reformatted with defaults.
2. Both tools support config-driven scope (`files.includes` for Biome, `.prettierignore` for Prettier), but **PostToolUse hooks run in parallel with no ordering guarantee**, so two formatters competing on the same file is a real parallel-write race — not just an idempotence question.
3. `bunx` caches the underlying npm package; splitting the monolith into multiple per-language plugins does not duplicate installs.

Given those facts, the cleanest design is to **let the plugin boundary itself encode scope** rather than relying on tool config. Each per-language plugin matches only its extensions via the wrapper's whitelist, so two non-overlapping plugins (e.g. `biome-json-formatter` + `prettier-yaml-formatter`) cannot race — their matchers are physically disjoint.

The monolith is offered alongside as a one-click convenience for users whose only answer is "format everything this tool supports" — its whitelist is the union of the subsets.

### Formatter coexistence rules (documented in every formatter README)

Three installation modes are supported:

1. **Install a monolith** (`biome-formatter` or `prettier-formatter`) — everything that tool covers.
2. **Install one or more per-language subsets** (`biome-js-formatter`, `prettier-yaml-formatter`, etc.) — pick languages.
3. **Mix across tools** (`biome-js-formatter` + `prettier-yaml-formatter`) — each tool owns its extensions, no overlap.

Unsupported — will cause parallel-write race:

- Monolith **plus** a subset of the same tool (e.g. `biome-formatter` + `biome-json-formatter` both fire on `.json`).
- Two subsets from different tools claiming the same extension (e.g. `biome-json-formatter` + `prettier-json-formatter`).

The hook wrappers do **not** attempt to detect the race; they just run. README in every formatter plugin calls this out explicitly.

### Why no config-presence gating

An earlier draft considered wrappers that check for `biome.json` / `.prettierrc*` before firing. The research showed the approach works but requires (a) tool-specific flags like `--no-errors-on-unmatched`, (b) walking up to the `.git` root in shell, and (c) users to keep their configs disjoint to avoid the parallel-write race. Net, it pushes complexity into every user's project rather than into our plugin boundaries. The monolith-plus-subsets split achieves the same end (user picks scope) without requiring any project-level configuration.

## LSP specifications

### `biome-lsp`

```json
{
  "name": "biome-lsp",
  "source": "./plugins/biome-lsp",
  "strict": false,
  "lspServers": {
    "biome": {
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/launch-biome-lsp.sh",
      "args": ["lsp-proxy"],
      "extensionToLanguage": {
        ".js": "javascript", ".jsx": "javascriptreact",
        ".mjs": "javascript", ".cjs": "javascript",
        ".ts": "typescript", ".tsx": "typescriptreact",
        ".mts": "typescript", ".cts": "typescript",
        ".json": "json", ".jsonc": "jsonc",
        ".css": "css",
        ".graphql": "graphql", ".gql": "graphql"
      }
    }
  }
}
```

Wrapper: shared JS/TS launcher with `PKG=@biomejs/biome`, `BIN=biome`. Biome's LSP entry point is the subcommand `lsp-proxy`, passed via `args` (not via the wrapper).

**Overlap with `typescript-lsp`**: both register `.ts`/`.tsx`. Claude Code's behavior with overlapping LSPs is an open question — see §"Open questions". Document the overlap in README; instruct users to disable one per-project if double-diagnostics are noisy.

### `tombi-lsp`

```json
{
  "name": "tombi-lsp",
  "source": "./plugins/tombi-lsp",
  "strict": false,
  "lspServers": {
    "tombi": {
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/launch-tombi-lsp.sh",
      "args": ["lsp"],
      "extensionToLanguage": { ".toml": "toml" }
    }
  }
}
```

Wrapper: **Python chain** launcher with `PKG=tombi`, `BIN=tombi`. The `python -m` fallback branch is skipped (tombi doesn't reliably expose a `-m` entry).

README should note tombi's schema awareness for `pyproject.toml` / `Cargo.toml` and briefly compare to Taplo for users already familiar with the latter.

### `yaml-lsp`

```json
{
  "name": "yaml-lsp",
  "source": "./plugins/yaml-lsp",
  "strict": false,
  "lspServers": {
    "yaml": {
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/launch-yaml-lsp.sh",
      "args": ["--stdio"],
      "extensionToLanguage": { ".yaml": "yaml", ".yml": "yaml" }
    }
  }
}
```

Wrapper: shared JS/TS launcher with `PKG=yaml-language-server`, `BIN=yaml-language-server`.

README mentions the built-in schema catalog (GitHub Actions, Kubernetes, docker-compose). The server fetches schemas over the network by default — see §"Open questions" for the air-gapped concern.

### `vscode-html-lsp`

```json
{
  "name": "vscode-html-lsp",
  "source": "./plugins/vscode-html-lsp",
  "strict": false,
  "lspServers": {
    "vscode-html": {
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/launch-vscode-html-lsp.sh",
      "args": ["--stdio"],
      "extensionToLanguage": { ".html": "html", ".htm": "html" }
    }
  }
}
```

Wrapper (`scripts/launch-vscode-html-lsp.sh`), **bespoke**:

```sh
#!/usr/bin/env sh
set -eu

try() { command -v "$1" >/dev/null 2>&1; }

if try bunx; then
  exec bunx -p vscode-langservers-extracted vscode-html-language-server "$@"
fi
if try pnpm; then
  exec pnpm --package=vscode-langservers-extracted dlx vscode-html-language-server -- "$@"
fi
if try npx; then
  exec npx -y --package=vscode-langservers-extracted vscode-html-language-server -- "$@"
fi

echo "error: none of bunx / pnpm / npx found on PATH" >&2
echo "tried to launch: vscode-html-language-server (from vscode-langservers-extracted)" >&2
echo "install one of: https://bun.sh  |  https://pnpm.io  |  https://nodejs.org" >&2
exit 127
```

### `vscode-css-lsp`

Same shape as `vscode-html-lsp`, with:

- `BIN` → `vscode-css-language-server`
- `extensionToLanguage` → `{ ".css": "css", ".scss": "scss", ".less": "less" }`

### `vscode-json-lsp`

Same shape as `vscode-html-lsp`, with:

- `BIN` → `vscode-json-language-server`
- `extensionToLanguage` → `{ ".json": "json", ".jsonc": "jsonc" }`

**Overlap with `biome-lsp`**: both register `.json`/`.jsonc`. Biome contributes lint + formatting diagnostics; vscode-json contributes schema-based completion (tsconfig.json / package.json / composer.json). Document; users can disable one if noisy.

### `bash-lsp`

```json
{
  "name": "bash-lsp",
  "source": "./plugins/bash-lsp",
  "strict": false,
  "lspServers": {
    "bash": {
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/launch-bash-lsp.sh",
      "args": ["start"],
      "extensionToLanguage": { ".sh": "shellscript", ".bash": "shellscript" }
    }
  }
}
```

Wrapper: shared JS/TS launcher with `PKG=bash-language-server`, `BIN=bash-language-server`. The server integrates `shellcheck` automatically if it's on PATH; we don't install it — README notes that diagnostic quality depends on system `shellcheck`.

## Formatter specifications

### Shared wrapper shape

Every formatter plugin has `scripts/<name>-format-hook.sh` shaped as:

```sh
#!/usr/bin/env sh
set -eu

# 1. Parse event JSON from stdin; extract tool_input.file_path.
FILE=$(python3 -c 'import json,sys;d=json.load(sys.stdin);print(d.get("tool_input",{}).get("file_path",""))')
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0

# 2. Extension whitelist (per-plugin: inline list here).
case "$FILE" in
  *.js|*.mjs|*.cjs|*.jsx|*.ts|*.mts|*.cts|*.tsx|*.d.ts) ;;   # in-scope
  *) exit 0 ;;                                                # out-of-scope, silent
esac

# 3. Run the tool via the JS/TS chain launcher.
try() { command -v "$1" >/dev/null 2>&1; }
if try bunx;  then exec bunx @biomejs/biome format --write -- "$FILE"; fi
if try pnpm;  then exec pnpm dlx @biomejs/biome -- format --write -- "$FILE"; fi
if try npx;   then exec npx -y  @biomejs/biome format --write -- "$FILE"; fi

# 4. Graceful-miss: no runtime available → warn on stderr, exit 0.
echo "warning: biome-formatter: no bunx/pnpm/npx on PATH; skipping format of $FILE" >&2
exit 0
```

This matches `ruff-formatter` in v2 (graceful-miss semantics; never block Claude's turn on missing runtime). The per-plugin differences are:

- The `case` extension whitelist.
- The npm package and tool subcommand in the `try` block.

MultiEdit path iteration (v2 Open Question #2): if the `tool_input` exposes multiple file paths under MultiEdit, the extraction line must iterate. **This is a hard dependency on Phase 1's resolution of that question.** Phase 2 wrappers use the resolved contract directly; if Phase 1 lands with `file_path` as the only field, Phase 2 inherits that limitation until the upstream contract improves.

### Formatter matchers (marketplace fragment)

All formatters use the same `matcher` and differ only in `command`. Example for `biome-json-formatter`:

```json
{
  "name": "biome-json-formatter",
  "source": "./plugins/biome-json-formatter",
  "strict": false,
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          { "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/biome-json-format-hook.sh",
            "timeout": 15 }
        ]
      }
    ]
  }
}
```

The remaining 9 formatter plugins (`biome-formatter`, `biome-js-formatter`, `prettier-formatter`, `prettier-js-formatter`, `prettier-json-formatter`, `prettier-css-formatter`, `prettier-html-formatter`, `prettier-markdown-formatter`, `prettier-yaml-formatter`) each have the same fragment shape with the `name`, `source`, and `command` path adjusted. The only substantive differences are **the extension whitelist** and **the tool command** inside the script:

| Plugin | Extension whitelist (`case` patterns) | Tool command |
|---|---|---|
| `biome-formatter` | `*.js\|*.mjs\|*.cjs\|*.jsx\|*.ts\|*.mts\|*.cts\|*.tsx\|*.d.ts\|*.json\|*.jsonc` | `@biomejs/biome format --write -- "$FILE"` |
| `biome-js-formatter` | `*.js\|*.mjs\|*.cjs\|*.jsx\|*.ts\|*.mts\|*.cts\|*.tsx\|*.d.ts` | same |
| `biome-json-formatter` | `*.json\|*.jsonc` | same |
| `prettier-formatter` | union of all prettier per-language whitelists below | `prettier --write -- "$FILE"` |
| `prettier-js-formatter` | `*.js\|*.mjs\|*.cjs\|*.jsx\|*.ts\|*.mts\|*.cts\|*.tsx` | same |
| `prettier-json-formatter` | `*.json\|*.json5\|*.jsonc` | same |
| `prettier-css-formatter` | `*.css\|*.scss\|*.less` | same |
| `prettier-html-formatter` | `*.html\|*.htm` | same |
| `prettier-markdown-formatter` | `*.md\|*.markdown\|*.mdx` | same |
| `prettier-yaml-formatter` | `*.yaml\|*.yml` | same |

## Templates

Add one new template to `templates/`:

- `templates/formatter-hook-plugin/` — reference skeleton for a PostToolUse formatter plugin. Mirrors the existing `ruff-formatter` shape. Contains:
  - `README.md` — "when to use, how to fill in the blanks"
  - `.claude-plugin/plugin.json.example` — metadata skeleton
  - `scripts/format-hook.sh.example` — the script above with `# EDIT ME` markers for the `case` whitelist and the tool command
  - `marketplace-entry.example.json` — fragment to paste into root `marketplace.json`

No new LSP template needed — the existing `js-ts-tool-plugin` and `python-tool-plugin` already cover all seven Phase 2 LSP plugins. (`vscode-*-lsp` uses the `js-ts-tool-plugin` template plus a bespoke-wrapper note in its README.)

## Rollout order

Ordered by implementation risk and incremental pattern coverage. Each step gates on the prior passing v2's smoke matrix (one runtime at a time: `bun`, `pnpm`, `npm`, `uv`, `pipx`, none).

1. **`bash-lsp`** — simplest single-server LSP, zero special cases. Fastest second-use of the JS/TS launcher.
2. **`yaml-lsp`** — same pattern. Pair with bash-lsp in one PR.
3. **`tombi-lsp`** — first second-use of the Python launcher outside Phase 1. Proves the chain transfers cleanly.
4. **`vscode-html-lsp`** — first bespoke wrapper in Phase 2. Prove the multi-binary `bunx -p` pattern on one server before replicating.
5. **`vscode-css-lsp` + `vscode-json-lsp`** — copy the html plugin with binary name changed.
6. **`biome-lsp`** — monolith LSP; exercises overlap-with-typescript-lsp story.
7. **`biome-formatter`** + **`prettier-formatter`** — monolith formatters. Pair in one PR so overlap documentation is written once.
8. **Per-language formatter subsets** — 2 biome + 6 prettier = 8 plugins. Each is a copy of its monolith with a narrower `case` whitelist. Land as one or two PRs.

## Verification

Per v2 §"Verification", manual in this phase. Each plugin README carries its own check:

- **LSPs**: open a file with a matching extension, confirm diagnostics / hover.
- **`vscode-*-lsp`**: verify each of the three plugins starts its intended binary; install two together, confirm both servers spawn.
- **Monolith formatter**: ask Claude to write a deliberately-misformatted file with an in-scope extension; verify on-disk result is reformatted.
- **Subset formatter**: verify it reformats in-scope extensions **and** leaves out-of-scope extensions untouched.
- **Coexistence sanity**:
  - `biome-js-formatter` + `prettier-yaml-formatter` installed together: write `.ts` → only biome fires; write `.yaml` → only prettier fires. No race.
  - `biome-formatter` + `biome-json-formatter` installed together (the unsupported case): write `.json` → both fire; document that on-disk corruption is possible and tell the user to uninstall one.

CI automation remains out of scope.

## Failure handling

All Phase 2 plugins inherit v2's failure-handling contract unchanged:

- LSPs: exit 127 with actionable stderr when no runtime is available.
- Formatters: exit 0 silently on out-of-scope file extensions; exit 0 with a warning on stderr when the runtime is missing; exit non-zero only when the tool itself failed.

## Open questions

Resolve during implementation; do not block the rollout.

1. **Overlapping LSP dispatch** — what does Claude Code do when two LSPs register the same extension (`biome-lsp` + `typescript-lsp` on `.ts`, `biome-lsp` + `vscode-json-lsp` on `.json`)? Three possibilities: both spawn and contribute diagnostics, first-registered wins, last-registered wins. Verify during `biome-lsp` implementation. If "first wins," the per-project disable instructions in the READMEs must be more prominent.
2. **Prettier config discovery** — prettier reads project config (`.prettierrc*`, `package.json`) from cwd. Confirm that running via `bunx` with cwd at the Claude Code launch directory still discovers project config correctly.
3. **Biome config discovery** — same question for `biome.json` / `biome.jsonc`.
4. **yaml-language-server schema fetch** — the server fetches remote schemas by default. In air-gapped environments this may hang or fail. Document; if it bites, add an opt-out env var (candidate: `YAML_LS_DISABLE_SCHEMA_DOWNLOAD`).
5. **MultiEdit file-path iteration** — inherited from v2 Open Question #2. Phase 2 wrappers use whatever contract Phase 1 lands with.
