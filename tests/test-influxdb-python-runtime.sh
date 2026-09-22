#!/usr/bin/env bash
set -euo pipefail

readonly IMAGE="${1:-localhost/addon-influxdb:verification}"
readonly CONTAINER_CLI="${CONTAINER_CLI:-podman}"

# shellcheck disable=SC2016 # Expanded by Bash inside the container.
"${CONTAINER_CLI}" run --rm --entrypoint /bin/bash "${IMAGE}" -c '
    set -euo pipefail

    pip_path="$(command -v pip)"
    [[ "${pip_path}" = /usr/lib/influxdb3/python/bin/pip ]]
    pip --version | grep -Fq "/usr/lib/influxdb3/python/lib/python3.13/site-packages/pip"
'

echo "InfluxDB bundled Python package manager is available"
