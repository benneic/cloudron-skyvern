# Skyvern for Cloudron

Unofficial [Cloudron](https://www.cloudron.io/) package for [Skyvern](https://github.com/Skyvern-AI/skyvern). One app runs the API, embedded Chromium, and the web UI. PostgreSQL and disk come from Cloudron addons.

This repository does not fork Skyvern. The image copies the published `public.ecr.aws/skyvern/skyvern` and `skyvern-ui` trees onto `cloudron/base`.

## Install

Catalog URL:

`https://raw.githubusercontent.com/benneic/cloudron-skyvern/main/CloudronVersions.json`

1. In the Cloudron dashboard, open **App Store → Community Apps** and add that URL, then install **Skyvern**.
2. Or with the CLI:

```bash
cloudron install --versions-url https://raw.githubusercontent.com/benneic/cloudron-skyvern/main/CloudronVersions.json
```

The first catalog entry appears after the release workflow has published an image. Until then the file lists no versions.

## What runs

| Piece | Role |
|-------|------|
| PostgreSQL addon | Tasks, workflows, built-in credential vault |
| Local storage | Artifacts, videos, logs, API key under `/app/data` |
| proxyauth | Cloudron users sign in to the dashboard |
| nginx :8080 | UI, `/api/v1` (API), `/api/mcp` (remote MCP), `/artifacts` |

Skyvern does not implement the Cloudron OIDC addon. There is one Skyvern organization and one API key. If Cloudron itself uses OIDC or LDAP, that applies only because proxyauth uses Cloudron accounts.

`/api` is outside the login wall so n8n, ActivePieces, and MCP clients can call it with `x-api-key`. The dashboard and `/artifacts` stay behind the Cloudron login.

## After install

1. Sign in at the app URL with a Cloudron user.
2. Set an LLM provider in the app environment, then restart. Example:

```text
ENABLE_OPENAI=true
OPENAI_API_KEY=sk-...
LLM_KEY=OPENAI_GPT5_5
```

3. Read the API key from `/app/data/.skyvern/credentials.toml`.

The default memory limit is 4 GiB. Raise it if the browser is killed.

- [Connect MCP, n8n, and ActivePieces](docs/INTEGRATIONS.md)
- [Credential vaults](docs/CREDENTIALS.md) (Bitwarden, 1Password, Azure Key Vault, custom HTTP)
- Upstream self-host docs: [Skyvern-AI/skyvern](https://github.com/Skyvern-AI/skyvern/tree/main/docs/developers/self-hosted)

## Maintainer builds

Local packaging checks use the Cloudron builder, not `cloudron build`:

```bash
cloudron builder login
cloudron builder build
cloudron versions add --last-build
```

To record an image you already pushed:

```bash
cloudron versions add --image ghcr.io/benneic/skyvern-cloudron:1.0.36
```

GitHub Actions does not call the Cloudron CLI. [upstream-watch.yml](.github/workflows/upstream-watch.yml) builds `ghcr.io/benneic/skyvern-cloudron:<version>` and runs `node scripts/publish-version.mjs`, which is the same result as `cloudron versions add --image`.

The workflow runs every Monday at 06:00 UTC and on **Actions → Upstream release watch → Run workflow**. It compares the latest [Skyvern release](https://github.com/Skyvern-AI/skyvern/releases) with `ARG SKYVERN_VERSION` and `CloudronManifest.json`. When upstream is newer it commits the bump, builds, updates `CloudronVersions.json`, tags `vX.Y.Z`, and opens a GitHub release. If `main` already matches upstream but the catalog entry is missing, it publishes without bumping again. Each run re-enables the workflow so GitHub does not disable the schedule after 60 days without activity.

In GitHub → Settings → Actions → General, set workflow permissions to **Read and write**. If `main` is protected, allow `github-actions[bot]` to push.

Publishing by hand:

```bash
docker buildx build -t ghcr.io/benneic/skyvern-cloudron:1.0.36 --build-arg SKYVERN_VERSION=1.0.36 --push .
npm ci
node scripts/publish-version.mjs 'ghcr.io/benneic/skyvern-cloudron:1.0.36'
```

## License

Packaging in this repository is [MIT](LICENSE). Skyvern itself is licensed by [Skyvern-AI/skyvern](https://github.com/Skyvern-AI/skyvern).

Replace `contactEmail` in [CloudronManifest.json](CloudronManifest.json) before you rely on the community listing for support mail.
