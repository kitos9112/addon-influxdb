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
declare node_id
declare wal_dir
declare corrupt_wal_dir
declare license_email
declare license_file
declare token_value
declare -a corrupt_wals

export LD_LIBRARY_PATH="/usr/lib/influxdb3/python/lib:${LD_LIBRARY_PATH:-}"
export PYTHONHOME="/usr/lib/influxdb3/python"
export PYTHONPATH="/usr/lib/influxdb3/python/lib/python3.13"

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
node_id="$(bashio::config 'node_id')"

if [[ -n "${license_email}" ]] || [[ -n "${license_file}" ]]; then
    edition="enterprise"
fi

if [[ -z "${edition}" ]]; then
    edition="core"
fi

if [[ -z "${node_id}" ]]; then
    node_id="ha-node"
fi

binary="/usr/bin/influxdb3-${edition}"
if ! bashio::fs.file_exists "${binary}"; then
    bashio::exit.nok "InfluxDB 3 ${edition} binary missing at ${binary}"
fi

ln -sf "${binary}" /usr/bin/influxdb3
echo "${edition}" > "${data_dir}/edition"

wal_dir="${data_dir}/data/${node_id}/wal"
corrupt_wal_dir="${data_dir}/corrupt-wal/${node_id}"

if [[ -d "${wal_dir}" ]]; then
    mapfile -t corrupt_wals < <(find "${wal_dir}" -maxdepth 1 -type f -name '*.wal' -size 0c | sort)
    if (( ${#corrupt_wals[@]} > 0 )); then
        mkdir -p "${corrupt_wal_dir}"
        for wal in "${corrupt_wals[@]}"; do
            mv "${wal}" "${corrupt_wal_dir}/$(basename "${wal}")"
        done
        bashio::log.warning "Moved ${#corrupt_wals[@]} zero-byte WAL file(s) to ${corrupt_wal_dir}."
    fi
fi

admin_token="$(bashio::config 'admin_token')"
if bashio::var.has_value "${admin_token}"; then
    if [[ ! "${admin_token}" =~ ^apiv3_ ]]; then
        bashio::exit.nok "Provided admin_token is invalid. It must start with 'apiv3_'."
    fi
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

if bashio::fs.file_exists "${token_file}"; then
    token_value="$(grep -oE '"token"[[:space:]]*:[[:space:]]*"[^"]+"' "${token_file}" \
        | head -n 1 \
        | sed -E 's/.*"token"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
    if [[ -z "${token_value}" ]]; then
        bashio::log.warning "Admin token file is empty or malformed; regenerating."
        influxdb3 create token --admin --offline --output-file "${token_file}" > /dev/null 2>&1
        token_value="$(grep -oE '"token"[[:space:]]*:[[:space:]]*"[^"]+"' "${token_file}" \
            | head -n 1 \
            | sed -E 's/.*"token"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
        echo "${token_value}" > "${token_plain}"
    elif [[ ! "${token_value}" =~ ^apiv3_ ]]; then
        if bashio::var.has_value "${admin_token}"; then
            bashio::exit.nok "Provided admin_token is invalid. It must start with 'apiv3_'."
        fi
        bashio::log.warning "Admin token file contains invalid token; regenerating."
        influxdb3 create token --admin --offline --output-file "${token_file}" > /dev/null 2>&1
        token_value="$(grep -oE '"token"[[:space:]]*:[[:space:]]*"[^"]+"' "${token_file}" \
            | head -n 1 \
            | sed -E 's/.*"token"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
        echo "${token_value}" > "${token_plain}"
    fi
fi

if ! bashio::fs.file_exists "${token_plain}"; then
    bashio::log.warning "Admin token plaintext file missing; auth may be misconfigured."
fi

chmod 0600 "${token_file}" "${token_plain}" 2>/dev/null || true
