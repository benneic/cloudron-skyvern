# Credential vaults

Skyvern can store logins in its own database, or read them at runtime from a vault you already run. The cloud product configures some of these on a Settings page. This package uses environment variables on the Cloudron app, or the credentials API. Restart the app after changing environment variables.

Secrets stay in Cloudron's environment store or in your vault. They are not part of the image.

## Skyvern vault

No extra configuration. Create password, card, or secret credentials in the UI or with `POST /api/v1/credentials`. They are stored in the PostgreSQL addon.

## Bitwarden or Vaultwarden

Set these on the Cloudron app:

| Variable | Purpose |
|----------|---------|
| `SKYVERN_AUTH_BITWARDEN_ORGANIZATION_ID` | Bitwarden organization id |
| `SKYVERN_AUTH_BITWARDEN_CLIENT_ID` | API client id (`user.…`) |
| `SKYVERN_AUTH_BITWARDEN_CLIENT_SECRET` | API client secret |
| `SKYVERN_AUTH_BITWARDEN_MASTER_PASSWORD` | Master password used to unlock the CLI |
| `BW_HOST` | HTTPS URL of Bitwarden or Vaultwarden |

When the client id is set and `BITWARDEN_SERVER` is empty, the package starts `bw serve` on `127.0.0.1:8002` and points Skyvern at it. Vaultwarden itself is a different app. Set `BITWARDEN_SERVER` (and `BITWARDEN_SERVER_PORT`) yourself if you already run a Bitwarden CLI server; this package will not start a second one.

The cloud flow that shares a collection with Skyvern staff does not apply here. Workflows reference a Bitwarden collection id and optional item id.

## 1Password

Create a [service account](https://developer.1password.com/docs/service-accounts/get-started/) that can read the vault. Then either:

- set `OP_SERVICE_ACCOUNT_TOKEN` on the Cloudron app, or
- `POST /api/v1/credentials/onepassword/create` with `x-api-key` and body `{ "token": "…" }`.

Workflow credential parameters use the 1Password vault id and item id.

## Azure Key Vault

`POST /api/v1/credentials/azure_credential/create` with `x-api-key`:

```json
{
  "credential": {
    "tenant_id": "…",
    "client_id": "…",
    "client_secret": "…"
  }
}
```

You can also set `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, and `AZURE_CREDENTIAL_VAULT` if you want the process environment to carry them. The app makes outbound HTTPS calls to Azure. There is no Azure addon.

## Custom webhook vault

Your service implements the create, get, and delete contract in the [external providers](https://www.skyvern.com/docs/cloud/managing-credentials/external-providers) doc. Every request from Skyvern sends `Authorization: Bearer <token>`.

Environment:

```bash
CREDENTIAL_VAULT_TYPE=custom
CUSTOM_CREDENTIAL_API_BASE_URL=https://credentials.example.com/api/v1/credentials
CUSTOM_CREDENTIAL_API_TOKEN=your_api_token
```

Or `POST /api/v1/credentials/custom_credential/create` with `api_base_url` and `api_token`.

`CREDENTIAL_VAULT_TYPE` must be `custom` for the environment variables to be used. Skyvern's default vault type is not custom.
