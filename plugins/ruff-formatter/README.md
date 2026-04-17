# ruff-formatter

A PostToolUse hook that runs [`ruff format`](https://docs.astral.sh/ruff/formatter/) on every `.py` / `.pyi` file Claude touches via `Write`, `Edit`, or `MultiEdit`. Never blocks the turn; failures surface as warnings on stderr.

## Runtime

Python chain, in order:

1. `uvx ruff format …` — preferred, isolated
2. `pipx run ruff format …` — fallback

Install one:

- https://docs.astral.sh/uv/ (provides `uvx`)
- https://pipx.pypa.io/

If neither is present, the hook logs a one-line skip warning and exits cleanly — the rest of the session continues.

## What it does

- After any `Write | Edit | MultiEdit`, the hook inspects the tool input.
- If the written file ends in `.py` or `.pyi`, it runs `ruff format <file>` in place.
- Any other extension exits silently.

## What it does NOT do

- No lint-fix pass (`ruff check --fix`) in this version. Adding it later would let automatic edits change semantics; keep scope tight for v1.
- No `--check` mode. The hook fires after a write; formatting in place is the point.
- No configuration passthrough from the project. Ruff picks up `pyproject.toml` / `ruff.toml` as usual via its own discovery rules.

## Files

- `.claude-plugin/plugin.json` — plugin metadata.
- `scripts/ruff-format-hook.sh` — POSIX sh hook script. Parses stdin JSON, extracts `tool_input.file_path`, runs the runtime fallback chain.

Runtime configuration (the `hooks` block) is declared at the marketplace level in the root `.claude-plugin/marketplace.json` entry for this plugin.

## Smoke testing

On a machine with only `uv` (no pipx, no global ruff):

```
bash -c 'printf "{\"tool_input\":{\"file_path\":\"/tmp/ruff-smoke.py\"}}\n" > /tmp/ev.json
         printf "x =  1+2\n" > /tmp/ruff-smoke.py
         scripts/ruff-format-hook.sh < /tmp/ev.json
         cat /tmp/ruff-smoke.py'
```

Expected output: `x = 1 + 2` (reformatted).
