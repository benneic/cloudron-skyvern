#!/bin/bash
set -euo pipefail

export PATH="/opt/skyvern-usr/bin:/opt/skyvern-ui-usr/bin:/usr/local/bin:/usr/bin:/bin${PATH:+:$PATH}"

if [ ! -f /run/skyvern/start-bitwarden ]; then
    exit 0
fi

export HOME=/app/data/bitwarden
mkdir -p "$HOME"
cd "$HOME"

if [ -n "${BW_HOST:-}" ]; then
    bw config server "$BW_HOST"
fi

status="$(bw status 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin).get("status",""))' || true)"
if [ "$status" != "locked" ] && [ "$status" != "unlocked" ]; then
    if [ -n "${BW_CLIENTID:-}" ] && [ -n "${BW_CLIENTSECRET:-}" ]; then
        bw login --apikey
    fi
fi

if [ -n "${BW_PASSWORD:-}" ]; then
    BW_SESSION="$(bw unlock --passwordenv BW_PASSWORD --raw)"
    export BW_SESSION
fi

PORT="${BITWARDEN_SERVER_PORT:-8002}"
exec bw serve --hostname 127.0.0.1 --port "$PORT"
