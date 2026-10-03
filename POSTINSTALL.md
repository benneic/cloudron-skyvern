## First steps

1. Open the app URL and sign in with your Cloudron account. That login is Cloudron proxyauth, not a Skyvern user.
2. Set an LLM provider under the app's **Environment** before you run tasks. Example: `ENABLE_OPENAI=true`, `OPENAI_API_KEY`, and `LLM_KEY`. Restart the app after saving.
3. Copy the API key from `/app/data/.skyvern/credentials.toml` (the `cred` value) or from the Skyvern UI. MCP, n8n, and ActivePieces use the header `x-api-key`.

## Connect other tools

- Integrations: https://github.com/benneic/cloudron-skyvern/blob/main/docs/INTEGRATIONS.md
- Credential vaults (Bitwarden, 1Password, Azure Key Vault, custom webhook): https://github.com/benneic/cloudron-skyvern/blob/main/docs/CREDENTIALS.md

## Resources

Browser automations need memory. This package asks for 4 GiB. Raise the app memory limit if Chromium is killed.

The API, `/mcp`, and `/artifacts` are not behind the Cloudron login page so automation can call them with the API key. Do not publish the API key.
