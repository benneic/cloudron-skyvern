# Cloudron image: reuse upstream Skyvern images on cloudron/base.
# Final stage must be cloudron/base (file manager, terminal, logs).
# Image tags on ECR include the leading "v" (v1.0.36). The ARG is semver without it
# so it stays aligned with CloudronManifest.json.

ARG SKYVERN_VERSION=1.0.55
FROM public.ecr.aws/skyvern/skyvern:v${SKYVERN_VERSION} AS backend
FROM public.ecr.aws/skyvern/skyvern-ui:v${SKYVERN_VERSION} AS ui

FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c
ARG SKYVERN_VERSION=1.0.55

LABEL org.opencontainers.image.title="Skyvern (Cloudron)"
LABEL org.opencontainers.image.version="${SKYVERN_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/Skyvern-AI/skyvern"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nginx \
        supervisor \
        postgresql-client \
        ca-certificates \
        xvfb \
        x11vnc \
        xterm \
        xauth \
        x11-utils \
    && rm -rf /var/lib/apt/lists/*

# Python, alembic, playwright, websockify, and bw live in the backend image's /usr/local.
# Keep them off cloudron/base's /usr/local so platform tooling stays intact.
COPY --from=backend /usr/local /opt/skyvern-usr
COPY --from=backend /app /opt/skyvern

# UI is a Node server. Node itself is the node:20 image's /usr/local.
COPY --from=ui /usr/local /opt/skyvern-ui-usr
COPY --from=ui /app /opt/skyvern-ui

ENV PATH="/opt/skyvern-usr/bin:/opt/skyvern-ui-usr/bin:${PATH}" \
    LD_LIBRARY_PATH="/opt/skyvern-usr/lib" \
    PYTHONPATH="/opt/skyvern" \
    PLAYWRIGHT_BROWSERS_PATH="/opt/ms-playwright"

# Upstream console scripts use #!/usr/local/bin/python3. The interpreter now lives
# under /opt/skyvern-usr, so recreate those shebang paths without replacing
# cloudron/base's own /usr/local tools when they already exist.
RUN set -eux; \
    mkdir -p /usr/local/bin; \
    for py in python3.11 python3 python; do \
      if [ -x "/opt/skyvern-usr/bin/${py}" ] && [ ! -e "/usr/local/bin/${py}" ]; then \
        ln -s "/opt/skyvern-usr/bin/${py}" "/usr/local/bin/${py}"; \
      fi; \
    done; \
    if [ ! -e /usr/local/bin/python3 ] && [ -x /opt/skyvern-usr/bin/python3.11 ]; then \
      ln -s /opt/skyvern-usr/bin/python3.11 /usr/local/bin/python3; \
    fi; \
    if [ ! -e /usr/local/bin/python ] && [ -e /usr/local/bin/python3 ]; then \
      ln -s python3 /usr/local/bin/python; \
    fi

# Chromium system libraries are not part of cloudron/base.
RUN playwright install-deps chromium \
    && playwright install chromium \
    && chmod -R a+rX /opt/ms-playwright

# Persist data through symlinks. /app/data is the only durable writable tree and is
# empty at runtime, so the links are created at build time and the targets at start.
RUN mkdir -p /data /app \
    && ln -sfn /app/data/artifacts /data/artifacts \
    && ln -sfn /app/data/videos /data/videos \
    && ln -sfn /app/data/har /data/har \
    && ln -sfn /app/data/log /data/log \
    && ln -sfn /app/data/.skyvern /app/.skyvern

# Public nginx owns 8080. The UI server hardcodes 8080; move it to 8081.
# Drop the desktop "open" call, which fails in a container.
RUN sed -i \
        -e 's|/app/dist|/opt/skyvern-ui/dist|g' \
        -e 's|/app/.skyvern|/app/data/.skyvern|g' \
        /opt/skyvern-ui/entrypoint-skyvernui.sh \
    && sed -i \
        -e 's/8080/8081/g' \
        -e '/await open(url)/d' \
        /opt/skyvern-ui/localServer.js

RUN mkdir -p /app/code /run/nginx /run/skyvern

COPY nginx/nginx.conf /app/code/nginx.conf
COPY supervisor/supervisord.conf /app/code/supervisord.conf
COPY start.sh /app/code/start.sh
COPY start-ui.sh /app/code/start-ui.sh
COPY bitwarden-serve.sh /app/code/bitwarden-serve.sh
RUN chmod +x /app/code/start.sh /app/code/start-ui.sh /app/code/bitwarden-serve.sh

EXPOSE 8080

CMD ["/app/code/start.sh"]
