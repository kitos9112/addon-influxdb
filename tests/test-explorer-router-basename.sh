#!/usr/bin/env bash
set -euo pipefail

readonly IMAGE="${1:?pass the image to test}"
readonly CONTAINER_CLI="${CONTAINER_CLI:-podman}"
REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPOSITORY_ROOT
readonly INGRESS_ENTRY="/api/hassio_ingress/test-token"

test_root="$(mktemp -d)"
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

cp "${REPOSITORY_ROOT}/tests/fixtures/nginx-explorer.conf" "${test_root}/nginx.conf"
cp "${REPOSITORY_ROOT}/influxdb/rootfs/etc/nginx/includes/explorer_subfilter.conf" \
    "${test_root}/explorer_subfilter.conf"
"${REPOSITORY_ROOT}/influxdb/rootfs/usr/local/bin/render-nginx-ingress" \
    "${INGRESS_ENTRY}" "${test_root}/explorer_subfilter.conf"

container_id="$("${CONTAINER_CLI}" run -d \
    --entrypoint nginx \
    --volume "${test_root}:/test:ro" \
    "${IMAGE}" \
    -c /test/nginx.conf -g 'daemon off;')"

bundle_file="$("${CONTAINER_CLI}" exec "${container_id}" sh -c \
    'grep -l "api/sessions" /app-root/_master_app/*.js | head -n 1')"
if [[ -z "${bundle_file}" ]]; then
    echo "Explorer session loader bundle not found" >&2
    exit 1
fi

bundle_url="${bundle_file#/app-root/_master_app}"
bundle_response=""
for _ in {1..30}; do
    if bundle_response="$("${CONTAINER_CLI}" exec "${container_id}" \
        curl --max-time 2 --silent --show-error --fail \
        "http://127.0.0.1:18081${bundle_url}" 2> /dev/null)"; then
        break
    fi
    sleep 0.1
done

expected_router='es=(0,s.Ys)(el,{basename:new URL(document.baseURI).pathname.slice(0,-1)||"/"})'
if [[ "${bundle_response}" != *"${expected_router}"* ]]; then
    echo "Explorer router was not given the ingress basename in served JavaScript" >&2
    "${CONTAINER_CLI}" logs "${container_id}" >&2
    exit 1
fi

echo "Explorer router uses the ingress basename"
