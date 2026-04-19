#!/usr/bin/env sh
# SessionStart / SessionEnd hook: submit tokscale stats for Claude Code + Codex.
# Contract:
#   - never blocks the session. Detaches via nohup, exits 0 immediately.
#   - stdin (Claude Code hook event JSON) is ignored.
# Env knobs:
#   TOKSCALE_AUTO_SUBMIT_DISABLE=1   skip entirely
#   TOKSCALE_AUTO_SUBMIT_DRY_RUN=1   pass --dry-run to tokscale
set -u

[ "${TOKSCALE_AUTO_SUBMIT_DISABLE:-0}" = "1" ] && exit 0

command -v bunx >/dev/null 2>&1 || {
  echo "tokscale-auto-submit: bunx not on PATH — install Bun (https://bun.sh) to enable." >&2
  exit 0
}

DRY=""
[ "${TOKSCALE_AUTO_SUBMIT_DRY_RUN:-0}" = "1" ] && DRY="--dry-run"

for client in claude codex; do
  # shellcheck disable=SC2086
  nohup bunx tokscale@latest submit --"$client" $DRY >/dev/null 2>&1 &
done

exit 0
