# Skyvern for Cloudron

[Skyvern](https://www.skyvern.com/) is an open source browser agent. You describe a task in natural language and it drives a browser to complete it. This package runs the self-hosted API, embedded Chromium, and web UI in one Cloudron app.

**What you get**

- **PostgreSQL** from Cloudron for tasks, workflows, and the built-in credential vault.
- **Local storage** for artifacts, recordings, logs, and the generated API key.
- **Dashboard login** through Cloudron proxyauth. Skyvern itself has one organization and one API key. It does not implement Cloudron OIDC.
- **API, MCP, n8n, and ActivePieces** on the same app URL. Those paths are outside the login wall and use the `x-api-key` header.

**Relationship to upstream**

This is unofficial packaging. The container reuses the published `public.ecr.aws/skyvern/skyvern` and `skyvern-ui` images on `cloudron/base`. Report product bugs to [Skyvern-AI/skyvern](https://github.com/Skyvern-AI/skyvern). Report packaging issues to this repository.

**Licensing**

Skyvern is licensed by its upstream project. This packaging repository is MIT.
