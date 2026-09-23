# Independent InfluxDB add-on release design

## Intent

Make `kitos9112/addon-influxdb` an installable Home Assistant add-on repository
that owns its metadata, documentation, image builds, and releases. A user who
adds this repository to Home Assistant should be able to install a published
image and receive subsequent updates when the add-on version increases.

## Repository identity

- Keep the repository URL `https://github.com/kitos9112/addon-influxdb` and the
  add-on folder and slug `influxdb`.
- Add root `repository.yaml` with this repository's name, URL, and maintainer.
- Change the add-on URL, OCI image metadata, badges, support links, code owners,
  and release documentation to this repository and its current maintainer.
- Keep the original MIT licence attribution in `LICENSE.md` and Git history.
  Remove inherited sponsorship, private contact, and community release
  references from active project metadata. Do not claim original authorship.
- Replace the inherited Debian base with the official, pinned Home Assistant
  Debian 13 base image so the release does not depend on the prior maintainer's
  image registry. Keep the existing runtime scripts and verify their behavior.

## Version and image contract

- Start the standalone release line at add-on version `7.0.0`. Local Git history
  contains tags through `v6.0.0`; the new major version also marks the change
  from the inherited InfluxDB 1 release line to this InfluxDB 3 implementation.
- `influxdb/config.yaml` advertises the generic multi-architecture image
  `ghcr.io/kitos9112/addon-influxdb`. Its `version` must equal an available
  image tag without the `v` prefix.
- The image is published for `amd64` and `aarch64`, with both a version tag and
  `latest`. Home Assistant resolves the generic image via a multi-architecture
  manifest. The package must be public for unauthenticated Home Assistant pulls.
- Each future release changes `config.yaml` to a new version, merges through
  CI, then pushes the matching `v<version>` tag. The tag is immutable.

## CI and release flow

- CI runs for pull requests, pushes to `main`, and manual dispatch. It checks
  YAML, shell scripts, Dockerfile, release metadata, ingress rendering, and the
  bundled Python runtime. It builds both supported architectures without
  publishing them. Pull requests receive read-only credentials.
- A tag matching `v*` starts the release workflow. It verifies that the tag
  matches `config.yaml`, that the tagged commit is on `main`, and that the full
  CI workflow passes at that commit.
- After verification, native amd64 and arm64 runners use the official Home
  Assistant builder actions to publish signed architecture-specific images.
  A final job publishes and signs the generic manifest, then creates GitHub
  release notes for the tag. Only this workflow has package and release write
  permissions. It uses the repository's `GITHUB_TOKEN` and no cross-repository
  dispatch secret.
- Release publication must not happen if either architecture, runtime check,
  or manifest job fails. A first-release checklist verifies anonymous pulls of
  the generic image before asking users to install it.

## Installation and migration

- Document adding this repository URL in Home Assistant's app store. Existing
  `local_influxdb` installations are separate apps and will not update from the
  GitHub repository. The new app has a repository-derived ID.
- Before removing the local app, back up its data and settings. The database,
  token, plugins, and Explorer state live in `/data/influxdb3` and
  `/data/explorer`; they need a deliberate migration to the new app's data
  volume. Update Home Assistant integrations that use the old app hostname.
- The repository release does not mutate or uninstall the user's running
  Home Assistant installation.

## Verification

- CI is green for a pull request and `main` at the release commit.
- The release workflow publishes both architecture images and the generic
  manifest with a tag matching `config.yaml`.
- An anonymous pull of the generic image succeeds for amd64 and aarch64.
- A local startup smoke test reaches the InfluxDB processing engine and serves
  Explorer JavaScript assets through the ingress-style path.
- The final handoff states whether the release was published or remains ready
  to tag, and that live Home Assistant migration still requires host access.
