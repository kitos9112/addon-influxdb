#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: InfluxDB 3
# Prepare InfluxDB 3 runtime and bootstrap admin token
# ==============================================================================
set -euo pipefail

declare edition
declare binary
declare data_dir
declare token_file
declare token_plain
declare admin_token
declare license_email
declare license_file

data_dir="/data/influxdb3"
token_file="${data_dir}/admin-token.json"
token_plain="${data_dir}/admin-token.txt"

mkdir -p \
    "${data_dir}/data" \
    "${data_dir}/plugins" \
    "/data/explorer" \
    "/data/explorer/config"

edition="$(bashio::config 'edition')"
license_email="$(bashio::config 'license_email')"
license_file="$(bashio::config 'license_file')"

if [[ -n "${license_email}" ]] || [[ -n "${license_file}" ]]; then
    edition="enterprise"
fi

if [[ -z "${edition}" ]]; then
    edition="core"
fi

binary="/usr/local/bin/influxdb3-${edition}"
if ! bashio::fs.file_exists "${binary}"; then
    bashio::exit.nok "InfluxDB 3 ${edition} binary missing at ${binary}"
fi

ln -sf "${binary}" /usr/local/bin/influxdb3
echo "${edition}" > "${data_dir}/edition"

admin_token="$(bashio::config 'admin_token')"
if bashio::var.has_value "${admin_token}"; then
    cat <<EOF > "${token_file}"
{
  "token": "${admin_token}",
  "name": "_admin"
}
EOF
    echo "${admin_token}" > "${token_plain}"
elif ! bashio::fs.file_exists "${token_file}"; then
    bashio::log.info "Generating InfluxDB 3 admin token (offline)..."
    influxdb3 create token --admin --offline --output-file "${token_file}" > /dev/null 2>&1
    grep -oE '"token"[[:space:]]*:[[:space:]]*"[^"]+"' "${token_file}" \
        | head -n 1 \
        | sed -E 's/.*"token"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' \
        > "${token_plain}"
fi

if ! bashio::fs.file_exists "${token_plain}"; then
    bashio::log.warning "Admin token plaintext file missing; auth may be misconfigured."
fi
