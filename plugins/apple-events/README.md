# apple-events

[FradSer/mcp-server-apple-events](https://github.com/FradSer/mcp-server-apple-events) MCP server — native macOS Reminders and Calendar integration via the EventKit framework.

Exposes CRUD operations on reminders, reminder lists, calendar events, and calendars, plus four built-in workflow prompts. Everything runs on-device through a Swift native bridge; no cloud hop, no third-party auth.

## Tools

| Tool | What it does |
| --- | --- |
| `reminders_tasks` | CRUD on reminders — priority, alarms, recurrence, location triggers, tags, subtasks |
| `reminders_subtasks` | Manage checklist items inside a reminder |
| `reminders_lists` | CRUD on reminder lists |
| `calendar_events` | CRUD on EventKit calendar events |
| `calendar_calendars` | List available calendars |

## Built-in prompts

These ship inside the MCP server and appear automatically as `/mcp__apple-events__<name>` once installed:

- `daily-task-organizer` — same-day execution blueprint
- `smart-reminder-creator` — turn a task idea into a scheduled reminder
- `reminder-review-assistant` — audit existing reminders
- `weekly-planning-workflow` — Mon–Sun weekly reset with calendar time blocks

## Runtime

`npx -y mcp-server-apple-events` — the npm package bundles a Swift binary that is compiled on first launch via Xcode Command Line Tools. Subsequent launches reuse the compiled binary.

## Prerequisites

1. **macOS only.** EventKit is not available on other platforms.
2. **Node.js 18+** on `PATH` (provides `npx`).
3. **Xcode Command Line Tools** — required for Swift compilation on first launch. Install with `xcode-select --install`.
4. **Permissions** — on first use macOS will prompt for Reminders and Calendar Full Access. Grant both. If the prompts do not appear, run `check-permissions.sh` from the [upstream repo](https://github.com/FradSer/mcp-server-apple-events) or open **System Settings → Privacy & Security → Reminders / Calendars** and grant access manually.

## Install

```text
/plugin marketplace add yousiki/claude-plugins
/plugin install apple-events@yousiki-claude-plugins
```

## Usage examples

```
Add a reminder to buy milk tomorrow at 9 AM
Schedule a dentist appointment next Tuesday at 2 PM on my Personal calendar
Show all my reminders due this week
Create a shopping list with bread, eggs, and coffee
```

## Files

- `.claude-plugin/plugin.json` — plugin metadata.
- `.mcp.json` — MCP server declaration (`npx -y mcp-server-apple-events`).

## Credits

Upstream MCP server by [FradSer](https://github.com/FradSer) — [mcp-server-apple-events](https://github.com/FradSer/mcp-server-apple-events). MIT license.
