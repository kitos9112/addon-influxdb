#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPOSITORY_ROOT
readonly RENDERER="${REPOSITORY_ROOT}/influxdb/rootfs/usr/local/bin/render-nginx-ingress"
readonly NGINX_INIT="${REPOSITORY_ROOT}/influxdb/rootfs/etc/cont-init.d/nginx.sh"
readonly INGRESS_ENTRY="/api/hassio_ingress/test-token"

test_root="$(mktemp -d)"
trap 'rm -rf "${test_root}"' EXIT

cp "${REPOSITORY_ROOT}/influxdb/rootfs/etc/nginx/servers/ingress.conf" "${test_root}/ingress.conf"
cp "${REPOSITORY_ROOT}/influxdb/rootfs/etc/nginx/includes/explorer_subfilter.conf" "${test_root}/explorer_subfilter.conf"

"${RENDERER}" \
    "${INGRESS_ENTRY}" \
    "${test_root}/ingress.conf" \
    "${test_root}/explorer_subfilter.conf"

if grep -R -F '%%ingress_entry%%' "${test_root}"; then
    echo "Unresolved ingress placeholder remains in rendered NGINX configuration" >&2
    exit 1
fi

grep -Fq "<base href=\"${INGRESS_ENTRY}/\">" "${test_root}/explorer_subfilter.conf"
grep -Fq "\"${INGRESS_ENTRY}/api/" "${test_root}/explorer_subfilter.conf"
grep -Fq "/etc/nginx/includes/explorer_subfilter.conf" "${NGINX_INIT}"

echo "Ingress templates rendered successfully"
