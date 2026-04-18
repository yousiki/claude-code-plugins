# browseros

[BrowserOS](https://www.browseros.com/) MCP server — drive the local BrowserOS agentic browser from Claude Code.

Exposes BrowserOS's built-in 53 browser-automation tools plus 40+ app integrations (Gmail, Slack, GitHub, Jira, Notion, Google Sheets, …) into the session over local HTTP. Everything runs on-device; no cloud hop for browser actions.

## Runtime

None. BrowserOS ships the MCP server inside the browser itself and exposes it on a local HTTP endpoint (e.g. `http://127.0.0.1:9000/mcp`). No API key, no launcher script, no npm/pip.

## Prerequisites

1. Install and launch the [BrowserOS browser](https://www.browseros.com/).
2. In BrowserOS, open `chrome://browseros/mcp` (or **Settings → BrowserOS as MCP**) and enable the MCP server. That settings page shows the exact URL Claude Code should connect to — **treat it as the authoritative source**, not any URL in docs or this README.
3. This plugin ships with `http://127.0.0.1:9000/mcp` (the URL current BrowserOS builds hand out). If your settings page shows a different port, edit the `url` for `browseros` in the root `.claude-plugin/marketplace.json` (marketplace-level `mcpServers` block) before installing.

External-service auth (Gmail, Slack, …) is handled by BrowserOS itself via OAuth on first use; Claude Code never sees those credentials.

## Files

- `.claude-plugin/plugin.json` — plugin metadata.

The `mcpServers` block is declared at the marketplace level in the root `.claude-plugin/marketplace.json` entry for this plugin.
