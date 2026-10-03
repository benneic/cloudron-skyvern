#!/bin/bash
set -euo pipefail

export PATH="/opt/skyvern-usr/bin:/opt/skyvern-ui-usr/bin:/usr/local/bin:/usr/bin:/bin${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/opt/skyvern-usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PYTHONPATH="/opt/skyvern"
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/opt/ms-playwright}"

mkdir -p \
    /app/data/artifacts \
    /app/data/videos \
    /app/data/har \
    /app/data/log \
    /app/data/.skyvern \
    /app/data/.skyvern/credential_vault \
    /app/data/temp \
    /app/data/bitwarden \
    /run/nginx/client_body \
    /run/nginx/proxy \
    /run/nginx/fastcgi \
    /run/nginx/uwsgi \
    /run/nginx/scgi \
    /run/skyvern \
    /tmp

chown -R cloudron:cloudron /app/data /run/skyvern /run/nginx

urlencode() {
    python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

if [ -z "${CLOUDRON_POSTGRESQL_HOST:-}" ] || [ -z "${CLOUDRON_POSTGRESQL_USERNAME:-}" ] || [ -z "${CLOUDRON_POSTGRESQL_DATABASE:-}" ]; then
    echo "Cloudron PostgreSQL addon env is missing" >&2
    exit 1
fi

USER_ENC="$(urlencode "${CLOUDRON_POSTGRESQL_USERNAME}")"
PASS_ENC="$(urlencode "${CLOUDRON_POSTGRESQL_PASSWORD:-}")"
PORT="${CLOUDRON_POSTGRESQL_PORT:-5432}"
export DATABASE_STRING="postgresql+psycopg://${USER_ENC}:${PASS_ENC}@${CLOUDRON_POSTGRESQL_HOST}:${PORT}/${CLOUDRON_POSTGRESQL_DATABASE}"

export ARTIFACT_STORAGE_PATH=/app/data/artifacts
export VIDEO_PATH=/app/data/videos
export HAR_PATH=/app/data/har
export LOG_PATH=/app/data/log
export SKYVERN_CREDENTIALS_FILE=/app/data/.skyvern/credentials.toml
# The built-in vault encrypts passwords on disk. The default is ~/.skyvern,
# which is read-only here. The Fernet key is created inside this directory.
export LOCAL_CREDENTIAL_VAULT_PATH=/app/data/.skyvern/credential_vault
# The UI process mints browser sessions against this URL. The public origin
# is for the browser; the UI server itself must stay on the loopback API.
export SKYVERN_API_BASE_URL="${SKYVERN_API_BASE_URL:-http://127.0.0.1:8000/api/v1}"

export BROWSER_TYPE="${BROWSER_TYPE:-chromium-headless}"
export BROWSER_STREAMING_MODE="${BROWSER_STREAMING_MODE:-cdp}"
export BROWSER_REMOTE_DEBUGGING_URL="${BROWSER_REMOTE_DEBUGGING_URL:-http://127.0.0.1:9222}"
export ENABLE_CODE_BLOCK="${ENABLE_CODE_BLOCK:-true}"
export VITE_BROWSER_STREAMING_MODE="${VITE_BROWSER_STREAMING_MODE:-cdp}"

ORIGIN="${CLOUDRON_APP_ORIGIN:-}"
if [ -z "$ORIGIN" ]; then
    ORIGIN="https://${CLOUDRON_APP_DOMAIN:-localhost}"
fi
ORIGIN="${ORIGIN%/}"

if [ -z "${VITE_API_BASE_URL:-}" ]; then
    export VITE_API_BASE_URL="${ORIGIN}/api/v1"
fi
if [ -z "${VITE_ARTIFACT_API_BASE_URL:-}" ]; then
    export VITE_ARTIFACT_API_BASE_URL="${ORIGIN}/artifacts"
fi
if [ -z "${VITE_WSS_BASE_URL:-}" ]; then
    case "$ORIGIN" in
        https://*)
            export VITE_WSS_BASE_URL="wss://${ORIGIN#https://}/api/v1"
            ;;
        http://*)
            export VITE_WSS_BASE_URL="ws://${ORIGIN#http://}/api/v1"
            ;;
        *)
            export VITE_WSS_BASE_URL="wss://${ORIGIN}/api/v1"
            ;;
    esac
fi

# External vaults: pass through whatever Cloudron env already set.
# Only start a local Bitwarden CLI server when the user configured Bitwarden
# and did not point BITWARDEN_SERVER at an existing CLI bridge.
if [ -n "${SKYVERN_AUTH_BITWARDEN_CLIENT_ID:-}" ] && [ -z "${BITWARDEN_SERVER:-}" ]; then
    export BITWARDEN_SERVER="http://127.0.0.1"
    export BITWARDEN_SERVER_PORT="${BITWARDEN_SERVER_PORT:-8002}"
    export BW_CLIENTID="${BW_CLIENTID:-$SKYVERN_AUTH_BITWARDEN_CLIENT_ID}"
    export BW_CLIENTSECRET="${BW_CLIENTSECRET:-${SKYVERN_AUTH_BITWARDEN_CLIENT_SECRET:-}}"
    export BW_PASSWORD="${BW_PASSWORD:-${SKYVERN_AUTH_BITWARDEN_MASTER_PASSWORD:-}}"
    touch /run/skyvern/start-bitwarden
fi

exec /usr/bin/supervisord -n -c /app/code/supervisord.conf
