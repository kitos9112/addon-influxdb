# InfluxDB 3 for Home Assistant

[![CI](https://github.com/kitos9112/addon-influxdb/actions/workflows/ci.yaml/badge.svg)](https://github.com/kitos9112/addon-influxdb/actions/workflows/ci.yaml)
[![Release](https://img.shields.io/github/v/release/kitos9112/addon-influxdb)](https://github.com/kitos9112/addon-influxdb/releases)
[![License](https://img.shields.io/github/license/kitos9112/addon-influxdb)](LICENSE.md)

A Home Assistant add-on for InfluxDB 3 with the Explorer web interface. It
supports `amd64` and `aarch64` systems and runs InfluxDB Core or Enterprise.

![InfluxDB 3 Explorer in Home Assistant](images/screenshot.png)

## Install

In Home Assistant, open **Settings → Add-ons → Add-on Store → Repositories** and
add `https://github.com/kitos9112/addon-influxdb`. Refresh the store, select
**InfluxDB 3**, install it, then start it and open its web UI. See the
[configuration and migration guide](influxdb/DOCS.md) before replacing an
existing InfluxDB add-on. Home Assistant builds the container locally during
installation and updates. Allow extra time and disk space, and ensure the host
can reach the upstream image registries and package repositories used by the
Dockerfile. A build can fail if an upstream dependency becomes unavailable.

This is an independent repository. Its add-on has a different Home Assistant ID
and data volume from `local_influxdb` and the former community add-on. Adding
this repository does not update either of those existing installations.

## Releases

CI runs on pull requests and changes to `main`: it checks metadata and scripts,
tests ingress rendering, and builds and smoke-tests both supported architectures
without publishing images.
A release is created by updating `influxdb/config.yaml` to the intended version,
merging that change into `main`, and pushing a matching `v<version>` tag. The
release workflow verifies the tag and CI, then creates a source-only GitHub
release. It does not publish a prebuilt container image. Home Assistant uses
the source in this repository to build each installation and update locally.

## Support and contributing

Report bugs and request improvements in [this repository's issues](https://github.com/kitos9112/addon-influxdb/issues).
Pull requests are welcome; see [CONTRIBUTING.md](.github/CONTRIBUTING.md).
For private vulnerability reports, see [SECURITY.md](.github/SECURITY.md).

## License

The add-on source in this repository is MIT-licensed; see [LICENSE.md](LICENSE.md)
for the original and current copyright notices. InfluxDB 3, InfluxDB 3
Explorer, and other components pulled into the container at build time are
third-party software governed by their own licenses. The MIT license does not
grant rights to redistribute those components.
Review their upstream terms before installing, especially the Enterprise
[At-Home license](https://www.influxdata.com/legal/influxdata-end-user-software-license-agreement/)
and Explorer's `/app-root/license.txt` in its upstream container image. The
original MIT copyright notice is retained because the add-on derives from that
work; it does not identify the current maintainer.
