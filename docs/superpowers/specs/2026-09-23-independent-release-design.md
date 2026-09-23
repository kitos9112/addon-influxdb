# Independent InfluxDB add-on release design

## Intent

Make `kitos9112/addon-influxdb` an installable Home Assistant add-on repository
that owns its metadata, documentation, build checks, and releases. A user who
adds this repository to Home Assistant should be able to build the add-on on
their own machine and receive subsequent updates when its version increases.
The first standalone release is `v1.0.0` and contains source, not a prebuilt
container image.

## Repository identity

- Keep the repository URL `https://github.com/kitos9112/addon-influxdb` and the
  add-on folder and slug `influxdb`.
- Add root `repository.yaml` with this repository's name, URL, and maintainer.
- Change the add-on URL, OCI image metadata, badges, support links, code owners,
  and release documentation to this repository and its current maintainer.
- Keep the original MIT licence attribution in `LICENSE.md` and Git history,
  and add the current maintainer's copyright for their contributions.
  Remove inherited sponsorship, private contact, and community release
  references from active project metadata. Do not claim original authorship.
- Replace the inherited Debian base with the official, pinned Home Assistant
  Debian 13 base image so the release does not depend on the prior maintainer's
  image registry. Keep the existing runtime scripts and verify their behavior.

## Version and local-build contract

- Start the independent release line at add-on version `1.0.0`. An inherited
  local `v1.0.0` tag points to the former repository's history; preserve its
  commit under a clearly named legacy ref before replacing the local tag.
  The independent remote has no release tags yet.
- Omit the optional `image` key from `influxdb/config.yaml` so Home Assistant
  Supervisor builds the add-on from its Dockerfile on each user's machine.
  Keep `amd64` and `aarch64` support and the existing Core, Enterprise, and
  Explorer runtime behavior.
- Do not publish the resulting image to GHCR or attach it to a GitHub release.
  The Dockerfile pulls upstream images during each local installation/update;
  installation is slower and can fail if an upstream image or build dependency
  becomes unavailable. The upstream component licenses govern those local
  copies, not this repository's MIT license.
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
- After verification, the release workflow creates GitHub release notes for
  the tag. It has `contents: write` only where needed to create the release;
  no job has package write access or pushes an image.
- Release publication must not happen if either architecture build or runtime
  check fails. A release-contract test ensures the add-on has no `image` key
  and the release workflow cannot publish containers. GitHub's source archive
  is the only release artifact.

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
- Explain that Supervisor builds locally, which takes longer, consumes more
  resources, requires access to the upstream image registries, and makes users
  responsible for their upstream license obligations.

## Verification

- CI is green for a pull request and `main` at the release commit.
- The release workflow publishes only a GitHub release for the matching tag;
  neither its permissions nor its steps can publish a container image.
- The source-only add-on metadata has no `image` key and passes Home Assistant
  metadata checks on both supported architectures.
- A local startup smoke test reaches the InfluxDB processing engine and serves
  Explorer JavaScript assets through the ingress-style path.
- The final handoff states whether the release was published or remains ready
  to tag, and that live Home Assistant migration still requires host access.
