# Linear MCP Configuration

## Authentication

Linear's hosted MCP endpoint at `https://mcp.linear.app/mcp` supports two auth methods:

- **OAuth 2.1** — browser-based flow, recommended for single-account use via the Claude Code Linear plugin
- **API Key** — passed via `Authorization: Bearer <token>` header, ideal for per-project configuration

API keys are generated in Linear: Settings > Security & Access > Personal API keys.

## Per-Project Setup (Multiple Accounts)

To use different Linear accounts per project (e.g., work vs personal), disable the global Linear plugin and use project-level `.mcp.json` files with API key auth.

If both projects may be open in the same shell session, use distinct env var names:

**Work project:**
```json
{
  "linear": {
    "type": "http",
    "url": "https://mcp.linear.app/mcp",
    "headers": {
      "Authorization": "Bearer ${LINEAR_API_KEY}"
    }
  }
}
```

**Personal project:**
```json
{
  "linear": {
    "type": "http",
    "url": "https://mcp.linear.app/mcp",
    "headers": {
      "Authorization": "Bearer ${LINEAR_API_KEY_PERSONAL}"
    }
  }
}
```

### Security

- Never put raw API keys in `.mcp.json` — use `${ENV_VAR}` syntax
- Keep `.mcp.json` committable by referencing env vars only
- Store actual keys in `.env` (gitignored), shell profile, or a secrets manager

## OAuth Notes

- OAuth 2.1 with dynamic client registration is the default for the Claude Code Linear plugin
- Access tokens are valid for 24 hours and require refresh
- Apps created after 2025-10-01 have refresh tokens enabled by default
- Apps created before then must migrate by 2026-04-01

## References

- [Linear MCP Docs](https://linear.app/docs/mcp)
- [Linear OAuth 2.0 Developers](https://linear.app/developers/oauth-2-0-authentication)
- [MCP Auth in Claude Code Guide](https://www.truefoundry.com/blog/mcp-authentication-in-claude-code)
