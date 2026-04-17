# Claude Code Plugin Marketplace Design (v2)

Supersedes [2026-04-16-marketplace-design.md](2026-04-16-marketplace-design.md). Revised after confirming the real shape of the official marketplace, the `lspServers` manifest field, and the execution constraints on `command`/`args`.

## Goal

Build a curated Claude Code plugin marketplace in this repository that:

1. Matches the official marketplace layout closely enough that plugins can be cross-read by anyone familiar with `anthropics/claude-plugins-official`.
2. Removes the "global install" assumption that the upstream LSP plugins ship with. Users with only `uv` or only `bun` should be able to launch every plugin in scope without a separate install step.
3. Stays intentionally narrow in scope: six language-tool plugins, no attempt to mirror the full upstream marketplace.

### In-scope plugins

Adapted from upstream:

- `context7` (MCP, JS/TS chain)
- `pyright-lsp` (LSP, JS/TS chain — pyright is npm-first)
- `typescript-lsp` (LSP, JS/TS chain)

New:

- `basedpyright-lsp` (LSP, Python chain)
- `ty-lsp` (LSP, Python chain, **pre-1.0 / beta**)
- `ruff-formatter` (hook, Python chain)

## Key Findings From Upstream Survey

These findings drive concrete design changes vs. the v1 document.

1. **Marketplace root is `.claude-plugin/marketplace.json`.** It is the authoritative list; per-plugin directories can be docs-only when `strict: false`. Official LSP plugins in `anthropics/claude-plugins-official` use exactly this shape — `plugins/pyright-lsp/` only ships `LICENSE` and `README.md`; all startup config is in the root manifest.
2. **LSP integration is a manifest field, not MCP, not hooks.** A plugin entry (in `marketplace.json` or `plugin.json`) carries `lspServers.<name> = { command, args, extensionToLanguage, ... }`. Claude Code spawns `command` with `args` over stdio.
3. **`command` is a single executable, not a shell fragment.** There is no `||` fallback, no shell expansion of `$PATH` alternatives. If the bare binary is missing, the LSP fails to start. This is the core reason the upstream plugins ship as "you must `npm install -g` first."
4. **`${CLAUDE_PLUGIN_ROOT}` resolves to an absolute path inside the plugin dir** and is available to `command`, `args`, `env`, and hook `command` strings. This is the escape hatch we need: we put a wrapper script in the plugin dir and point `command` at it.
5. **`uvx` / `bunx` are transparent over stdio.** They spawn the real binary as a child and pass stdio through, so `command: "uvx"`, `args: ["basedpyright-langserver", "--stdio"]` works for LSP without any wrapper — the wrapper is only needed when we want a **fallback chain** across runtimes.
6. **`ruff` has no official npm package.** The v1 decision to route it through the Python chain is confirmed as the only reasonable option.
7. **`ty` is beta (0.0.31 as of 2026-04-17), breaking changes between patch releases.** Must be marked clearly in README and kept opt-in.
8. **`pyright` is primarily distributed via npm.** The PyPI package is a thin bootstrap that downloads the npm release at runtime. Treating `pyright-lsp` as JS/TS-chain (v1's call) matches reality.
9. **Hooks receive event JSON on stdin.** `PostToolUse` for `Write|Edit|MultiEdit` contains `tool_input.file_path`. A ruff-formatter hook must parse that, not rely on env vars.

## Repo Layout

```
claude-code-plugins/
├── .claude-plugin/
│   └── marketplace.json          # Authoritative: name, owner, plugin list, strict:false entries
├── plugins/
│   ├── context7/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── .mcp.json
│   │   ├── scripts/launch-context7.sh
│   │   └── README.md
│   ├── typescript-lsp/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── scripts/launch-typescript-lsp.sh
│   │   └── README.md
│   ├── pyright-lsp/…
│   ├── basedpyright-lsp/…
│   ├── ty-lsp/…
│   └── ruff-formatter/
│       ├── .claude-plugin/plugin.json
│       ├── hooks/hooks.json
│       ├── scripts/ruff-format-hook.sh
│       └── README.md
├── templates/
│   ├── js-ts-tool-plugin/        # Reference skeleton + README (not code generator)
│   └── python-tool-plugin/
├── docs/
│   └── superpowers/specs/
└── README.md
```

Conventions:

- **Every plugin has a `.claude-plugin/plugin.json`** with at minimum `name`, `version`, `description`, `author`. The marketplace entry then uses `strict: false` and carries the runtime configuration (`lspServers` / `mcpServers` / `hooks`) at the marketplace level. This mirrors `plugins/pyright-lsp/` upstream.
- **All fallback logic lives in `plugins/<name>/scripts/*.sh`.** Manifest `command` points at the script via `${CLAUDE_PLUGIN_ROOT}/scripts/<launcher>.sh`.
- **Templates are documentation, not code generators.** Each template directory holds a README plus an example `plugin.json` / example manifest fragment. Copy-paste is the intended workflow.

## Manifest Strategy

### `marketplace.json` (root)

```json
{
  "name": "yousiki-claude-plugins",
  "owner": { "name": "yousiki", "email": "you.siki@outlook.com" },
  "plugins": [
    { "name": "context7",        "source": "./plugins/context7",        "category": "development", "strict": false, "mcpServers": { "…": "…" } },
    { "name": "typescript-lsp",  "source": "./plugins/typescript-lsp",  "category": "development", "strict": false, "lspServers": { "…": "…" } },
    { "name": "pyright-lsp",     "source": "./plugins/pyright-lsp",     "category": "development", "strict": false, "lspServers": { "…": "…" } },
    { "name": "basedpyright-lsp","source": "./plugins/basedpyright-lsp","category": "development", "strict": false, "lspServers": { "…": "…" } },
    { "name": "ty-lsp",          "source": "./plugins/ty-lsp",          "category": "development", "strict": false, "lspServers": { "…": "…" } },
    { "name": "ruff-formatter",  "source": "./plugins/ruff-formatter",  "category": "development", "strict": false, "hooks":       { "…": "…" } }
  ]
}
```

### `plugin.json` (each plugin)

Metadata only — never encodes runtime. Example:

```json
{
  "name": "pyright-lsp",
  "version": "0.1.0",
  "description": "Pyright language server, launched via bunx/pnpm dlx/npx fallback without requiring a global install.",
  "author": { "name": "yousiki" },
  "homepage": "https://github.com/yousiki/claude-code-plugins/tree/main/plugins/pyright-lsp",
  "license": "MIT"
}
```

Rationale for splitting metadata from runtime:

- Keeps per-plugin directories readable and small.
- Lets us swap the launcher script without editing per-plugin manifests.
- Matches upstream's `strict: false` LSP plugins exactly.

## Runtime Fallback Strategy

Every plugin that executes an external tool uses a plugin-local wrapper script. The script is the sole `command` in the manifest.

### Why a wrapper script

- `lspServers[*].command` is a single executable; no shell fallback is possible in JSON.
- Wrappers let us keep the v1 ordering ("bunx first, then pnpm dlx, then npx") and give us a single place to emit actionable error messages when every runtime is missing.
- Wrappers are small, POSIX-sh, no dependencies.

### JS/TS chain (`plugins/<name>/scripts/launch.sh`)

```sh
#!/usr/bin/env sh
# Generic JS/TS launcher. Caller sets PKG and BIN; we exec the first available runtime.
set -eu

PKG="${1:?package required}"      # e.g. typescript-language-server
BIN="${2:?bin required}"          # e.g. typescript-language-server
shift 2

try() { command -v "$1" >/dev/null 2>&1; }

if try bunx;    then exec bunx    "$PKG" "$@";        fi
if try pnpm;    then exec pnpm    dlx "$PKG" -- "$@"; fi
if try npx;     then exec npx -y  "$PKG" -- "$@";     fi

echo "error: none of bunx / pnpm / npx found on PATH" >&2
echo "tried to launch: $BIN ($PKG)" >&2
echo "install one of: https://bun.sh  |  https://pnpm.io  |  https://nodejs.org" >&2
exit 127
```

Each plugin then ships a thin wrapper that just fills `PKG`/`BIN`. (Alternatively: one shared launcher lives under `templates/` and each plugin symlinks / copies — decision below, see Open Questions.)

### Python chain (`plugins/<name>/scripts/launch.sh`)

```sh
#!/usr/bin/env sh
set -eu

PKG="${1:?}"            # e.g. basedpyright
BIN="${2:?}"            # e.g. basedpyright-langserver  (may differ from PKG)
shift 2

try() { command -v "$1" >/dev/null 2>&1; }

if try uvx;    then exec uvx    --from "$PKG" "$BIN" "$@"; fi
if try pipx;   then exec pipx   run --spec "$PKG" "$BIN" "$@"; fi
if try python; then
  # Fallback: assume already installed in current python; most bins expose `python -m <module>`.
  # The per-plugin wrapper decides the module name.
  exec python -m "${PY_MODULE:-$PKG}" "$@"
fi

echo "error: none of uvx / pipx / python found on PATH" >&2
echo "tried to launch: $BIN (from $PKG)" >&2
echo "install one of: https://docs.astral.sh/uv/  |  pipx  |  a system python3" >&2
exit 127
```

Notes:

- `uvx --from <pkg> <bin>` is the correct form when the console script name differs from the package name (basedpyright case).
- `pipx run --spec` mirrors the same behavior.
- `python -m` fallback only works when the tool ships a `__main__`; `ruff` does not, so ruff-formatter disables that branch.

## Plugin Specifications

Each block gives the marketplace entry fragment, the wrapper script contract, and verification notes.

### `context7` (MCP, JS/TS chain)

- **Upstream shape**: `npx -y @upstash/context7-mcp`.
- **Our adaptation**: route through `launch-context7.sh`, which tries bunx → pnpm dlx → npx.

Marketplace fragment:

```json
{
  "name": "context7",
  "source": "./plugins/context7",
  "strict": false,
  "mcpServers": {
    "context7": {
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/launch-context7.sh"
    }
  }
}
```

Wrapper: `exec bunx @upstash/context7-mcp` (with pnpm dlx / npx fallback). No extra args.

Verification: running Claude Code with this plugin should bring up the context7 MCP tools with `bun`, `pnpm`, or `npm` individually present.

### `typescript-lsp` (LSP, JS/TS chain)

- **Upstream shape**: `command: "typescript-language-server"`, expects global install.
- **Our adaptation**: wrapper runs `typescript-language-server --stdio` via bunx/pnpm/npx.

Marketplace fragment:

```json
{
  "name": "typescript-lsp",
  "source": "./plugins/typescript-lsp",
  "strict": false,
  "lspServers": {
    "typescript": {
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/launch-typescript-lsp.sh",
      "args": ["--stdio"],
      "extensionToLanguage": {
        ".ts": "typescript", ".tsx": "typescriptreact",
        ".js": "javascript", ".jsx": "javascriptreact",
        ".mts": "typescript", ".cts": "typescript",
        ".mjs": "javascript", ".cjs": "javascript"
      }
    }
  }
}
```

Wrapper notes: upstream's `typescript-language-server` also needs `typescript` in scope. `bunx typescript-language-server` resolves `typescript` transitively when running against a project that has its own `typescript` dep, otherwise we explicitly add it: `bunx -p typescript -p typescript-language-server typescript-language-server`. The wrapper should encode both forms.

### `pyright-lsp` (LSP, JS/TS chain)

- **Why JS/TS chain**: `pyright` is npm-first; the PyPI package bootstraps the npm release at runtime, which makes the PyPI path slower and less deterministic.
- **Binary**: `pyright-langserver` (not `pyright`).

Marketplace fragment:

```json
{
  "name": "pyright-lsp",
  "source": "./plugins/pyright-lsp",
  "strict": false,
  "lspServers": {
    "pyright": {
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/launch-pyright-lsp.sh",
      "args": ["--stdio"],
      "extensionToLanguage": { ".py": "python", ".pyi": "python" }
    }
  }
}
```

Wrapper: `exec bunx -p pyright pyright-langserver "$@"` (with fallbacks).

### `basedpyright-lsp` (LSP, Python chain)

- **Binary**: `basedpyright-langserver`. Package: `basedpyright`. Names differ → `uvx --from` is required.

Marketplace fragment:

```json
{
  "name": "basedpyright-lsp",
  "source": "./plugins/basedpyright-lsp",
  "strict": false,
  "lspServers": {
    "basedpyright": {
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/launch-basedpyright-lsp.sh",
      "args": ["--stdio"],
      "extensionToLanguage": { ".py": "python", ".pyi": "python" }
    }
  }
}
```

Wrapper: `exec uvx --from basedpyright basedpyright-langserver "$@"` (with pipx run fallback; skip the `python -m` branch — basedpyright doesn't expose a reliable `-m` entry).

Docs guidance: README must explain when to prefer this over `pyright-lsp` (stricter by default, additional diagnostics, community-maintained) and note that installing both is harmless — Claude Code will run whichever LSPs the user enables per-project.

### `ty-lsp` (LSP, Python chain, beta)

- **Package & binary**: both `ty`. Subcommand `ty server` starts the LSP (no `--stdio` flag; stdio is the default transport).

Marketplace fragment:

```json
{
  "name": "ty-lsp",
  "source": "./plugins/ty-lsp",
  "strict": false,
  "lspServers": {
    "ty": {
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/launch-ty-lsp.sh",
      "args": ["server"],
      "extensionToLanguage": { ".py": "python", ".pyi": "python" }
    }
  }
}
```

Wrapper: `exec uvx ty "$@"` (with pipx run fallback).

README must include an **unmissable "Beta" banner**: version is `0.0.x`, API not stable, breaking changes between patch releases — pin a tested version in the wrapper (`uvx ty@0.0.31 server`) once we validate one.

### `ruff-formatter` (hook, Python chain)

Not an LSP and not an MCP — a PostToolUse hook that reformats `.py` files after Claude writes them.

Marketplace fragment:

```json
{
  "name": "ruff-formatter",
  "source": "./plugins/ruff-formatter",
  "strict": false,
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          { "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/ruff-format-hook.sh",
            "timeout": 15 }
        ]
      }
    ]
  }
}
```

Wrapper `scripts/ruff-format-hook.sh`:

1. Read event JSON from stdin.
2. Extract `tool_input.file_path` (use `python3 -c 'import json,sys; …'` — avoids a `jq` dependency).
3. If the path does not end in `.py` or `.pyi`, exit 0 silently.
4. Run `uvx ruff format "$FILE"` (pipx run fallback). Swallow non-fatal stdout; surface errors on stderr with non-zero exit only if ruff itself failed.
5. Exit 0 so Claude's turn continues.

Design choices:

- **Format only** in v1 — no `ruff check --fix`. Adding lint fixes risks changing semantics silently; keep scope tight.
- **No `--check`** mode — the hook fires after a write, so formatting in place is the intended behavior.
- **`MultiEdit` matcher included** — a single MultiEdit call can touch many files; the hook runs once per tool call, so it must re-read the event to discover all edited paths. (If MultiEdit exposes a list, iterate; else fall back to the first path. Verify during implementation — see Open Questions.)

## Templates

`templates/js-ts-tool-plugin/` and `templates/python-tool-plugin/` exist as **copy-paste references**, not executable generators. Each contains:

- `README.md` — what this template is for, when to use it, how to fill in the blanks.
- `.claude-plugin/plugin.json.example` — metadata skeleton.
- `scripts/launch.sh.example` — the shared wrapper, with `# EDIT ME` markers for `PKG` / `BIN`.
- `marketplace-entry.example.json` — fragment to paste into root `marketplace.json`.

They do not need to be parseable plugins themselves; marketplace.json just omits them.

## Verification

Two layers, both manual in v1:

### Smoke matrix per plugin

For each LSP/MCP plugin, verify on a clean machine with **only one runtime installed** at a time:

- JS/TS chain plugins: test with only `bun`, then only `pnpm`, then only `npm`, then none.
- Python chain plugins: test with only `uv`, then only `pipx`, then none.
- "None" case: expect exit 127 with the actionable error message from the wrapper.

### End-to-end behavior

- `context7`: `/context7-search` (or equivalent MCP tool) returns results.
- Each LSP: open a file with the matching extension in a session, confirm diagnostics / hover.
- `ruff-formatter`: ask Claude to write a badly-formatted `.py` file, verify the on-disk result is ruff-formatted.

CI automation is out of scope for v1; document the manual steps in each plugin README.

## Rollout

Three phases, narrower than v1 to front-load risk.

### Phase 0 — scaffold

- Root `marketplace.json` skeleton, owner metadata, empty `plugins` array.
- `templates/` populated with the two skeletons and the shared wrapper scripts.
- Top-level `README.md` with install instructions (`/plugin marketplace add …`).

### Phase 1 — validate one plugin of each runtime family

Pick the simplest on each chain and take it end-to-end:

- `ruff-formatter` (Python chain, hook — smallest surface, exercises wrapper + hook flow).
- `context7` (JS/TS chain, MCP — exercises wrapper + MCP flow).

Outcome gate: both work on at least two runtime configurations before Phase 2 starts.

### Phase 2 — fill in the LSP plugins

In order of expected difficulty:

1. `typescript-lsp` (well-trodden path).
2. `pyright-lsp` (same chain, plus docs explaining the "pyright is npm despite being a Python tool" angle).
3. `basedpyright-lsp` (first Python-chain LSP, exercises `uvx --from`).
4. `ty-lsp` (beta — ship last so we can pin a tested version).

## Failure Handling

Every wrapper emits on stderr, on the "no runtime available" path:

- which binary it tried to launch
- which runtimes it checked, in order
- an actionable install pointer per runtime

The hook wrapper additionally:

- returns exit 0 when the edited file is out-of-scope (non-`.py`), so it's invisible in the common case
- returns non-zero only when ruff itself failed; never on "runtime missing" (we don't want missing `uv` to block Claude's turn — emit a warning and exit 0)

## Open Questions

Resolve during implementation; do not block Phase 0.

1. **Shared vs. copied wrapper**: do we keep one `templates/_shared/launch-js.sh` that plugins symlink to, or copy-paste into each plugin's `scripts/`? Copy-paste makes each plugin self-contained (better for the marketplace GitHub `source` story — a user can depend on one plugin without pulling templates). Symlink is DRY but fragile on Windows. **Tentative: copy-paste.**
2. **MultiEdit path iteration for ruff hook**: confirm whether a `MultiEdit` tool call's `tool_input` exposes the full list of edited files, and adjust the wrapper accordingly.
3. **Version pinning for beta tools**: once `ty` has a version we've tested end-to-end, pin it (`uvx ty@X.Y.Z server`) rather than floating. Revisit on each bump.
4. **User config hooks**: the official plugin spec supports `${user_config.*}` placeholders. We don't need them in Phase 1. Flag for a later iteration if users want to override package/version per-project.
5. **`typescript-lsp` workspace typescript**: decide whether the wrapper should auto-detect a project-local `typescript` (via `node_modules/.bin/tsc` presence) and prefer it over the bunx-installed version, to match what users expect from `typescript-language-server`. Safer default: always pull a fresh `typescript` from bunx; document the trade-off.
