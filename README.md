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
existing InfluxDB add-on. Installation requires a published, public GHCR image
for the version in `influxdb/config.yaml`; check the releases page first.

This is an independent repository. Its add-on has a different Home Assistant ID
and data volume from `local_influxdb` and the former community add-on. Adding
this repository does not update either of those existing installations.

## Releases

CI runs on pull requests and changes to `main`: it checks metadata and scripts,
tests ingress rendering, and builds and smoke-tests both supported images.
A release is created by updating `influxdb/config.yaml` to the intended version,
merging that change into `main`, and pushing a matching `v<version>` tag. The
release workflow verifies the tag and CI, publishes the multi-architecture
[GHCR image](https://github.com/kitos9112/addon-influxdb/pkgs/container/addon-influxdb),
checks that the image is anonymously accessible for both architectures, then
creates the GitHub release. GitHub may initially make a new GHCR package
private. For the first release, set the package to public in GitHub's package
settings and rerun the failed release job; the workflow will not create the
GitHub release until that access check passes.

## Support and contributing

Report bugs and request improvements in [this repository's issues](https://github.com/kitos9112/addon-influxdb/issues).
Pull requests are welcome; see [CONTRIBUTING.md](.github/CONTRIBUTING.md).
For private vulnerability reports, see [SECURITY.md](.github/SECURITY.md).

## License

MIT. See [LICENSE.md](LICENSE.md) for the original copyright and license notice.
