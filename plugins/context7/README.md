# context7

Upstash [Context7](https://github.com/upstash/context7) MCP server for up-to-date documentation lookup. Pulls version-specific docs and code examples into the session.

This is a marketplace-adapted version of Upstash's official `context7` plugin. The upstream plugin hardcodes `npx`; this version uses a runtime fallback wrapper so users with only `bun` or only `pnpm` can run it without installing anything globally.

## Runtime

JS/TS chain, in order:

1. `bunx` — https://bun.sh
2. `pnpm dlx` — https://pnpm.io
3. `npx -y` — bundled with Node.js

At least one must be on `PATH`. If none is present, Claude Code will see the MCP server fail to start; the wrapper logs an actionable error to stderr listing each runtime's install URL.

## Files

- `.claude-plugin/plugin.json` — plugin metadata.
- `.mcp.json` — MCP server declaration (stdio; points at the launcher below).
- `scripts/launch-context7.sh` — runtime fallback wrapper, invoked over stdio.

## Smoke test

```
plugins/context7/scripts/launch-context7.sh --help 2>&1 | head -5
```

Should print Context7's usage banner (or at least not fail with "command not found").
