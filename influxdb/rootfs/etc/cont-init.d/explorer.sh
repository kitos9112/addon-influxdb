#!/command/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: InfluxDB 3
# Prepare InfluxDB 3 Explorer configuration
# ==============================================================================
set -euo pipefail

declare default_database
declare token_plain

default_database="$(bashio::config 'default_database')"
token_plain="/data/influxdb3/admin-token.txt"

rm -rf /app-root/config
ln -s /data/explorer/config /app-root/config

if ! bashio::fs.file_exists "/data/explorer/config/config.json"; then
    if bashio::fs.file_exists "${token_plain}"; then
        token_value="$(cat "${token_plain}")"
    else
        token_value=""
        bashio::log.warning "Explorer config created without admin token; UI will require manual setup."
    fi

    cat <<EOF > /data/explorer/config/config.json
{
  "DEFAULT_INFLUX_SERVER": "http://127.0.0.1:8181",
  "DEFAULT_INFLUX_DATABASE": "${default_database:-homeassistant}",
  "DEFAULT_API_TOKEN": "${token_value}",
  "DEFAULT_SERVER_NAME": "Home Assistant InfluxDB 3"
}
EOF
fi
