# Connect agents and automation to this Skyvern

Replace `https://skyvern.example.com` with your Cloudron app origin (`CLOUDRON_APP_ORIGIN`).

The dashboard is behind Cloudron proxyauth. These paths are not:

| Path | Use |
|------|-----|
| `/api/v1` and `/v1` | REST API |
| `/mcp/` | Remote MCP (streamable HTTP) |
| `/artifacts/` | Screenshots and recordings |

Auth for all of them is the header `x-api-key`. Self-hosted Skyvern does not offer the Skyvern Cloud OAuth login used by `https://api.skyvern.com/mcp/`.

## API key

After the first start, Skyvern writes `/app/data/.skyvern/credentials.toml`. The `cred` value is the key.

```bash
cloudron exec --app skyvern.example.com -- cat /app/data/.skyvern/credentials.toml
```

Check the API:

```bash
curl -fsS "https://skyvern.example.com/api/v1/workflows" \
  -H "x-api-key: YOUR_SKYVERN_API_KEY"
```

## REST API

Base URL: `https://skyvern.example.com/api/v1` (the same routes also exist under `/v1`).

This is the same contract as upstream self-hosted Docker. SDK clients should set the base URL to that origin and send `x-api-key`.

## MCP (remote HTTP)

Point the client at `https://skyvern.example.com/mcp/` and send the API key. Do not use the Cloud URL or a browser sign-in flow.

Cursor (`~/.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "Skyvern": {
      "type": "streamable-http",
      "url": "https://skyvern.example.com/mcp/",
      "headers": {
        "x-api-key": "YOUR_SKYVERN_API_KEY"
      }
    }
  }
}
```

Claude Code:

```bash
claude mcp add-json skyvern '{"type":"http","url":"https://skyvern.example.com/mcp/","headers":{"x-api-key":"YOUR_SKYVERN_API_KEY"}}' --scope user
```

Upstream reference: [integrations/mcp/README.md](https://github.com/Skyvern-AI/skyvern/blob/main/integrations/mcp/README.md).

## MCP (stdio on your computer)

Install Skyvern's server extra on the machine that runs the assistant, and point it at this Cloudron app:

```json
{
  "mcpServers": {
    "Skyvern": {
      "command": "python",
      "args": ["-m", "skyvern", "run", "mcp"],
      "env": {
        "SKYVERN_BASE_URL": "https://skyvern.example.com",
        "SKYVERN_API_KEY": "YOUR_SKYVERN_API_KEY"
      }
    }
  }
}
```

## n8n

Install the Skyvern node. Create a credential with:

- API key: the `cred` value
- Base URL, if the node asks for one: `https://skyvern.example.com/api/v1`

Webhook callback URLs must be reachable from this Skyvern app (your n8n public URL). See the [n8n Skyvern docs](https://www.skyvern.com/docs/integrations/n8n).

## ActivePieces

Add the [Skyvern piece](https://www.activepieces.com/pieces/skyvern). Set the connection base URL to `https://skyvern.example.com/api/v1` and the API key to the `cred` value. Actions include Run Agent Task and Run Workflow.

## If a client is sent to the Cloudron login page

Machine calls must send `x-api-key` and must use `/api`, `/v1`, `/mcp`, or `/artifacts`. Those prefixes are excluded from proxyauth with `!regexp:^/(api|v1|mcp|artifacts)(/|$)`.

If something still hits the login wall, create a [Cloudron app access token](https://docs.cloudron.io/apps/#api-tokens) for the browser UI, or call Skyvern from another app on the same server using the public app URL and the API key. Do not put the API key in a public repository.
