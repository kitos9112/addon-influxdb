# Independent InfluxDB Add-on Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn this checkout into an independently maintained, installable Home Assistant add-on repository with a verified first release.

**Architecture:** Keep the existing `influxdb` app and runtime scripts. Move repository identity into `repository.yaml` and `config.yaml`, build on the official Home Assistant Debian base, run CI on changes, and publish signed multi-architecture images from version tags. Release automation creates the GitHub release only after image publication succeeds.

**Tech Stack:** Home Assistant app metadata, Docker/BuildKit, GitHub Actions, GHCR, Bash, NGINX, InfluxDB 3.

**Spec:** `docs/superpowers/specs/2026-09-23-independent-release-design.md`

## Global Constraints

- Repository URL: `https://github.com/kitos9112/addon-influxdb`.
- App slug: `influxdb`; first standalone version: `7.0.0`.
- Public generic image: `ghcr.io/kitos9112/addon-influxdb:7.0.0`.
- Architectures: `amd64` and `aarch64`.
- Preserve the original MIT attribution in `LICENSE.md` and Git history.
- Keep `/data/influxdb3` and `/data/explorer` layouts compatible with the existing local add-on.
- Never publish a GitHub release before both image builds and the manifest succeed.

## Review Focus

- A tag with a version different from `config.yaml` must fail before publishing.
- A tag pointing outside `main` must fail before publishing.
- A missing `aarch64` image must prevent manifest publication.
- A private GHCR package must be detected by an anonymous pull check before installation instructions claim readiness.
- A user with `local_influxdb` must understand that the repository install has a different app ID and data volume.

---

### Task 1: Own the repository and app metadata

**Files:** Create `repository.yaml`; modify `influxdb/config.yaml`, `influxdb/Dockerfile`, `.github/CODEOWNERS`, `LICENSE.md`; delete `influxdb/build.yaml`.

**Interfaces:** `repository.yaml` is read by Home Assistant's store. `config.yaml` version and image are consumed by Supervisor and the release workflow. Dockerfile labels describe the same image version and source.

- [ ] Check the current metadata: `rtk yq '.version, .image, .url' influxdb/config.yaml` and `rtk test -f repository.yaml` (the latter must fail initially).
- [ ] Add repository metadata with name `InfluxDB 3`, URL `https://github.com/kitos9112/addon-influxdb`, and maintainer `Marcos Soutullo (@kitos9112)`.
- [ ] Set `version: 7.0.0`, `image: ghcr.io/kitos9112/addon-influxdb`, and the repository URL in app config. Keep slug and data paths.
- [ ] Change Dockerfile base to pinned `ghcr.io/home-assistant/base-debian:trixie-2026.08.0`, replace active maintainer/OCI labels, and remove obsolete `build.yaml`.
- [ ] Confirm both `amd64` and `aarch64` base manifests and run a local build plus the existing Python runtime test. Confirm the InfluxDB server reaches startup with the new base.

### Task 2: Replace inherited project policy and documentation

**Files:** Modify `README.md`, `influxdb/DOCS.md`, `.github/CONTRIBUTING.md`, `.github/SECURITY.md`, `.github/CODE_OF_CONDUCT.md`, `.github/renovate.json`; delete `.github/FUNDING.yml`, `influxdb/.README.j2`, and inherited community maintenance workflows.

**Interfaces:** The README is the entry point for installation; DOCS explains options and migration; GitHub policy files point to current project channels.

- [ ] Enumerate inherited maintainer names, organization links, sponsorship,
      support contacts, and the old add-on ID throughout the repository.
- [ ] Replace active links and contacts with this repository. Keep the original copyright line only in `LICENSE.md`; link to that file from docs.
- [ ] Document adding this GitHub repository to Home Assistant and migrating `local_influxdb` data/settings deliberately before uninstalling the old app.
- [ ] Remove community repository updater, fundraising, and old release template files that are no longer consumed. Replace Renovate configuration with Dependabot for Docker and GitHub Actions if the latter covers all active dependency manifests.
- [ ] Re-run the reference scan and manually check every retained result is a technical dependency or required licence attribution.

### Task 3: Add independent CI

**Files:** Replace `.github/workflows/ci.yaml`; create a release-contract check under `tests/` only if it verifies a consumer-visible invariant; retain `tests/test-render-nginx-ingress.sh` and `tests/test-influxdb-python-runtime.sh`.

**Interfaces:** CI can be called by `.github/workflows/release.yaml`; every call performs metadata lint, shell/Dockerfile lint, ingress test, and image builds for both supported architectures without pushing.

- [ ] Run the existing test commands to establish a baseline: `rtk bash tests/test-render-nginx-ingress.sh` and `rtk shellcheck tests/*.sh`.
- [ ] For any new release contract script, first run it against the current `dev` metadata and verify it fails because no publishable image/version is declared.
- [ ] Implement jobs with `contents: read`; run tests and linters, then build/load each architecture on native runners using `home-assistant/builder/actions/build-image@2026.06.0` with `push: false`.
- [ ] Execute the Python runtime test against each loaded image. Run `actionlint`, `yamllint`, ShellCheck, Hadolint, and `git diff --check` locally.

### Task 4: Add tag-gated publication

**Files:** Create `.github/workflows/release.yaml`; update `README.md` with release instructions.

**Interfaces:** The release workflow calls CI, publishes `ghcr.io/kitos9112/{amd64,aarch64}-addon-influxdb:<version>`, publishes `ghcr.io/kitos9112/addon-influxdb:<version>` plus `latest`, then creates `v<version>` GitHub release notes.

- [ ] Add a gate that compares `${GITHUB_REF_NAME}` with `v$(yq -r '.version' influxdb/config.yaml)` and verifies the tagged commit is reachable from `origin/main`. Check wrong-tag and off-main cases locally before trusting it.
- [ ] Call CI at the tag. Give only the publish jobs `packages: write` and `id-token: write`; give only the final GitHub release job `contents: write`.
- [ ] Use Home Assistant builder's `build-image` and `publish-multi-arch-manifest` actions with the version as the primary tag and Cosign enabled. Make manifest depend on both architecture jobs; make GitHub release depend on manifest.
- [ ] Validate workflow syntax with actionlint. Confirm the release cannot publish from pull requests or an unverified tag.

### Task 5: Verify on GitHub and prepare the first release

**Files:** No product files after CI fixes; release notes come from the tag workflow.

**Interfaces:** GitHub Actions, GHCR, Home Assistant store URL.

- [ ] Commit coherent changes on `main` and push to the independent repository; confirm the push starts CI without manual dispatch.
- [ ] Inspect every CI job. Diagnose and fix failures, then repeat until both architectures and runtime checks pass.
- [ ] If the user chose publication, push `v7.0.0`, wait for the release workflow, make the new GHCR package public, and verify anonymous pulls for both platforms. Otherwise keep the verified commit ready to tag.
- [ ] Check `git status --short`, remote refs, release/image status, and document any live Home Assistant migration that still needs host access.
