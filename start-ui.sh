#!/bin/bash
set -euo pipefail

export PATH="/opt/skyvern-ui-usr/bin:/opt/skyvern-usr/bin:/usr/local/bin:/usr/bin:/bin${PATH:+:$PATH}"

CREDS="${SKYVERN_CREDENTIALS_FILE:-/app/data/.skyvern/credentials.toml}"

echo "Waiting for Skyvern API credentials at ${CREDS}"
for _ in $(seq 1 180); do
    if [ -s "$CREDS" ]; then
        break
    fi
    sleep 2
done

if [ ! -s "$CREDS" ]; then
    echo "credentials.toml was not created; UI will start without an API key" >&2
else
    # Upstream writes the compose hostname. This package reaches the API on localhost.
    sed -i 's#http://skyvern:8000/api/v1#http://127.0.0.1:8000/api/v1#g' "$CREDS"
fi

cd /opt/skyvern-ui
exec /bin/bash /opt/skyvern-ui/entrypoint-skyvernui.sh
