ARG EXPLORER_VERSION="1.9.0"
# hadolint ignore=DL3006
FROM influxdata/influxdb3-ui:${EXPLORER_VERSION} AS explorer-source

# Reinstall native Node.js dependencies for glibc; the Explorer image uses musl.
FROM node:26.9.0-bookworm-slim AS explorer-runtime
COPY --from=explorer-source /app-root /app-root
# hadolint ignore=DL3008
RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        g++ \
        make \
        python3 \
    && npm --prefix /app-root/_backend_app ci --omit=dev \
    && rm -fr \
        /tmp/* \
        /root/.npm \
        /var/lib/apt/lists/*

# hadolint ignore=DL3006
FROM influxdb:3.11.5-core AS core

# hadolint ignore=DL3006
FROM influxdb:3.11.5-enterprise AS enterprise

# hadolint ignore=DL3006
FROM ghcr.io/home-assistant/base-debian:trixie-2026.08.0

# Make the Python package manager bundled with InfluxDB discoverable by the
# processing engine. InfluxDB invokes `pip` by name during startup.
ENV PATH="/usr/lib/influxdb3/python/bin:${PATH}"

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base system
ARG BUILD_ARCH=amd64
# hadolint ignore=DL3008,SC3009
RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        libnginx-mod-http-lua \
        libstdc++6 \
        luarocks \
        nginx \
        openssl \
        procps \
    \
    && luarocks install lua-resty-http 0.15-0 \
    \
    && rm -fr \
        /tmp/* \
        /etc/nginx \
        /var/{cache,log}/* \
        /var/lib/apt/lists/* \
    \
    && mkdir -p /var/log/nginx \
    && touch /var/log/nginx/error.log

# Copy Explorer assets, glibc-native dependencies, and its matching Node.js runtime
COPY --from=explorer-runtime /app-root /app-root
COPY --from=explorer-runtime /usr/local/bin/node /usr/local/bin/node

# Copy InfluxDB 3 binaries and runtime deps
COPY --from=core /usr/bin/influxdb3 /usr/bin/influxdb3-core
COPY --from=enterprise /usr/bin/influxdb3 /usr/bin/influxdb3-enterprise
COPY --from=enterprise /usr/lib/influxdb3 /usr/lib/influxdb3
RUN \
    test "$(command -v pip)" = "/usr/lib/influxdb3/python/bin/pip" \
    && test -x /usr/lib/influxdb3/python/bin/pip \
    && pip --version > /dev/null

# Copy root filesystem
COPY rootfs /

# Build arguments provided by the Home Assistant builder
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="InfluxDB 3" \
    io.hass.description="InfluxDB 3 for Home Assistant" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="app" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Marcos Soutullo <kitos9112@users.noreply.github.com>" \
    org.opencontainers.image.title="InfluxDB 3" \
    org.opencontainers.image.description="InfluxDB 3 for Home Assistant" \
    org.opencontainers.image.vendor="kitos9112" \
    org.opencontainers.image.authors="Marcos Soutullo <kitos9112@users.noreply.github.com>" \
    org.opencontainers.image.url="https://github.com/kitos9112/addon-influxdb" \
    org.opencontainers.image.source="https://github.com/kitos9112/addon-influxdb" \
    org.opencontainers.image.documentation="https://github.com/kitos9112/addon-influxdb/blob/main/README.md" \
    org.opencontainers.image.version=${BUILD_VERSION}
