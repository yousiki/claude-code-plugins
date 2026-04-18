# deepwiki

Devin [DeepWiki](https://docs.devin.ai/work-with-devin/deepwiki-mcp) MCP server for AI-grounded Q&A over any public GitHub repository's wiki.

Exposes three tools into the session:

- `read_wiki_structure` — topic listings for a repo's generated wiki.
- `read_wiki_contents` — fetch page contents.
- `ask_question` — AI-powered, context-grounded answer about a repo.

## Runtime

None. DeepWiki is a remote streamable-HTTP MCP endpoint at `https://mcp.deepwiki.com/mcp`. No API key, no local process, no npm/pip.

Private repo access is out of scope for this plugin — use Devin's own authenticated MCP server for that.

## Files

- `.claude-plugin/plugin.json` — plugin metadata.
- `.mcp.json` — MCP server declaration (remote streamable HTTP, `https://mcp.deepwiki.com/mcp`).
