#!/usr/bin/env bash
set -euo pipefail

readonly IMAGE="${1:?pass the image to test}"
readonly CONTAINER_CLI="${CONTAINER_CLI:-podman}"

container_id="$("${CONTAINER_CLI}" run -d \
    --entrypoint /usr/bin/influxdb3-core \
    "${IMAGE}" \
    serve \
    --node-id smoke-test \
    --object-store file \
    --data-dir /tmp/influxdb3-smoke \
    --http-bind 127.0.0.1:8181 \
    --without-auth)"

# shellcheck disable=SC2317,SC2329 # Called by the EXIT trap.
cleanup() {
    "${CONTAINER_CLI}" rm -f "${container_id}" > /dev/null 2>&1 || true
}
trap cleanup EXIT

for _ in {1..60}; do
    if "${CONTAINER_CLI}" exec "${container_id}" \
        wget -q -O /dev/null http://127.0.0.1:8181/health; then
        echo "InfluxDB 3 HTTP health endpoint is ready"
        exit 0
    fi
    if [[ "$("${CONTAINER_CLI}" inspect -f '{{.State.Running}}' "${container_id}")" != true ]]; then
        "${CONTAINER_CLI}" logs "${container_id}"
        echo "InfluxDB server exited before becoming ready" >&2
        exit 1
    fi
    sleep 1
done

"${CONTAINER_CLI}" logs "${container_id}"
echo "InfluxDB server did not become ready within 60 seconds" >&2
exit 1
