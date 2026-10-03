#!/bin/bash
set -euo pipefail

mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# The upstream entrypoint starts Xvfb in the background and only reaps it on
# SIGTERM. A later crash leaves :99 held, and the next start exits immediately.
if [ -f /tmp/.X99-lock ]; then
    old_pid="$(awk 'NR==1 { print $1 }' /tmp/.X99-lock || true)"
    if [ -n "${old_pid}" ]; then
        kill "${old_pid}" 2>/dev/null || true
    fi
    rm -f /tmp/.X99-lock
fi
rm -f /tmp/.X11-unix/X99

exec /bin/bash /opt/skyvern/entrypoint-skyvern.sh
