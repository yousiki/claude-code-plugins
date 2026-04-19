# tokscale-auto-submit

A `SessionStart` + `SessionEnd` hook that fires `bunx tokscale@latest submit --claude` and `bunx tokscale@latest submit --codex` in the background every time a Claude Code session opens or closes. Detached via `nohup`, so the session never waits on the upload.

Why both events: `SessionEnd` can be skipped when the process is killed abruptly (crash, `kill -9`, laptop sleep, …). Pairing it with `SessionStart` guarantees the next session picks up whatever was missed.

## Runtime

- [Bun](https://bun.sh/) — required for `bunx`. If `bunx` is not on `PATH`, the hook logs a one-line skip warning and exits cleanly.
- No caching, no cooldown, no state file. Every trigger submits.

## What it does

On each `SessionStart` and `SessionEnd`:

1. Launches two detached `nohup bunx tokscale@latest submit --<client>` processes — one for `claude`, one for `codex`.
2. Redirects their stdout/stderr to `/dev/null`.
3. Returns 0 immediately.

## Environment knobs

| Var | Effect |
|-----|--------|
| `TOKSCALE_AUTO_SUBMIT_DISABLE=1` | Skip the hook entirely (for pairing / offline work). |
| `TOKSCALE_AUTO_SUBMIT_DRY_RUN=1` | Append `--dry-run` to each submit. Useful for smoke testing the wiring without hitting the tokscale backend. |

## What it does NOT do

- **No cooldown / rate limit.** If you open and close Claude Code ten times in a minute, you will submit twenty times. This is by design — the cost of a duplicate submit is lower than the cost of a missed one, and `nohup` keeps it off the session's critical path.
- **No log file.** Background output is discarded. If you need to debug a submit, run `bunx tokscale@latest submit --claude` manually in a terminal.
- **No other clients.** Hardcoded to `--claude` and `--codex` because those are the CLIs used with this plugin set. Fork and extend if you need more.

## Files

- `.claude-plugin/plugin.json` — plugin metadata.
- `scripts/submit-hook.sh` — POSIX sh hook script. Ignores stdin, detaches two `bunx` calls via `nohup`, exits 0.

Runtime configuration (the `hooks` block for `SessionStart` + `SessionEnd`) is declared at the marketplace level in the root `.claude-plugin/marketplace.json` entry for this plugin.

## Smoke testing

```sh
TOKSCALE_AUTO_SUBMIT_DRY_RUN=1 scripts/submit-hook.sh </dev/null
sleep 2
pgrep -laf 'tokscale.*submit'
```

Expected: the hook exits immediately; for a few seconds two `tokscale … submit --claude --dry-run` / `--codex --dry-run` processes are visible in `pgrep`, then they finish on their own.
