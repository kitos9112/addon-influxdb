ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:7.7.1
ARG EXPLORER_VERSION="1.6.2"
# hadolint ignore=DL3006
FROM influxdata/influxdb3-ui:${EXPLORER_VERSION} AS explorer

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
        openssl \
        procps \
    \
    && luarocks install lua-resty-http 0.15-0 \
    \
    && ARCH="${BUILD_ARCH}" \
    && if [ "${BUILD_ARCH}" = "aarch64" ]; then ARCH="arm64"; fi \
    \
    && curl -fsSL -o /tmp/influxdb3-core.tar.gz \
        "https://dl.influxdata.com/influxdb/releases/influxdb3-core-${INFLUXDB3_CORE_VERSION}_linux_${ARCH}.tar.gz" \
    && tar -xzf /tmp/influxdb3-core.tar.gz -C /tmp \
    && install -m 0755 /tmp/influxdb3 /usr/local/bin/influxdb3-core \
    \
    && curl -fsSL -o /tmp/influxdb3-enterprise.tar.gz \
        "https://dl.influxdata.com/influxdb/releases/influxdb3-enterprise-${INFLUXDB3_ENTERPRISE_VERSION}_linux_${ARCH}.tar.gz" \
    && tar -xzf /tmp/influxdb3-enterprise.tar.gz -C /tmp \
    && install -m 0755 /tmp/influxdb3 /usr/local/bin/influxdb3-enterprise \
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
COPY --from=explorer /usr/local/bin/node /usr/local/bin/node
COPY --from=explorer /usr/local/lib/node_modules /usr/local/lib/node_modules

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
