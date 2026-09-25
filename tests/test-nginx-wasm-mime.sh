#!/usr/bin/env bash
set -euo pipefail

readonly IMAGE="${1:?pass the image to test}"
readonly CONTAINER_CLI="${CONTAINER_CLI:-podman}"
REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPOSITORY_ROOT

test_root="$(mktemp -d)"
# NGINX workers run as an unprivileged user inside the container.
chmod 755 "${test_root}"
container_id=""

# shellcheck disable=SC2317,SC2329 # Called by the EXIT trap.
cleanup() {
    if [[ -n "${container_id}" ]]; then
        "${CONTAINER_CLI}" rm -f "${container_id}" > /dev/null 2>&1 || true
    fi
    rm -rf "${test_root}"
}
trap cleanup EXIT

cp "${REPOSITORY_ROOT}/tests/fixtures/nginx-wasm.conf" "${test_root}/nginx.conf"
touch "${test_root}/probe.wasm"

container_id="$("${CONTAINER_CLI}" run -d \
    --entrypoint nginx \
    --volume "${test_root}:/test:ro" \
    "${IMAGE}" \
    -c /test/nginx.conf -g 'daemon off;')"

content_type=""
for _ in {1..30}; do
    if content_type="$("${CONTAINER_CLI}" exec "${container_id}" \
        curl --max-time 2 --silent --show-error --fail \
        --output /dev/null --write-out '%{content_type}' \
        http://127.0.0.1:18080/probe.wasm 2> /dev/null)"; then
        break
    fi
    sleep 0.1
done

if [[ "${content_type}" != application/wasm ]]; then
    echo "Expected application/wasm for .wasm, got '${content_type}'" >&2
    "${CONTAINER_CLI}" logs "${container_id}" >&2
    exit 1
fi

echo "NGINX serves .wasm as application/wasm"
