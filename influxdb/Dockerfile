ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:7.7.1
ARG EXPLORER_VERSION="1.6.2"
# hadolint ignore=DL3006
FROM influxdata/influxdb3-ui:${EXPLORER_VERSION} AS explorer

# hadolint ignore=DL3006
FROM influxdb:3-core AS core

# hadolint ignore=DL3006
FROM influxdb:3-enterprise AS enterprise

# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base system
ARG BUILD_ARCH=amd64
ARG INFLUXDB3_CORE_VERSION="3.8.0"
ARG INFLUXDB3_ENTERPRISE_VERSION="3.8.0"
ARG EXPLORER_VERSION
RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        libnginx-mod-http-lua \
        luarocks \
        nginx \
        nodejs \
        npm \
        g++ \
        make \
        python3 \
        python3-pip \
        python3-venv \
        pkg-config \
        libsqlite3-dev \
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

# Copy Explorer assets and runtime
COPY --from=explorer /app-root /app-root

# Install Explorer backend sqlite3 driver (after assets are in place)
RUN npm --prefix /app-root/_backend_app install --omit=dev sqlite3

# Copy InfluxDB 3 binaries and runtime deps
COPY --from=core /usr/bin/influxdb3 /usr/bin/influxdb3-core
COPY --from=enterprise /usr/bin/influxdb3 /usr/bin/influxdb3-enterprise
COPY --from=enterprise /usr/lib/influxdb3 /usr/lib/influxdb3

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
