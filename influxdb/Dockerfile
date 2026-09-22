ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:9.4.0
ARG EXPLORER_VERSION="1.9.0"
# hadolint ignore=DL3006
FROM influxdata/influxdb3-ui:${EXPLORER_VERSION} AS explorer-source

# Reinstall native Node.js dependencies for glibc; the Explorer image uses musl.
FROM node:24.11.1-bookworm-slim AS explorer-runtime
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
FROM ${BUILD_FROM}

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

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Community Add-ons" \
    org.opencontainers.image.authors="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://addons.community" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
