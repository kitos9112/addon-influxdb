# Source-Only v1 Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish `v1.0.0` as a Home Assistant add-on that builds locally, with no public redistribution of bundled InfluxData images.

**Architecture:** Remove the optional `image` setting so Supervisor builds the existing Dockerfile on the user's machine. Keep CI's two architecture builds but remove all image-publication jobs from the tag workflow. Gate the GitHub release on matching metadata, `main` ancestry, and passing CI.

**Tech Stack:** Home Assistant app metadata, Docker/BuildKit, Ruby/Minitest, GitHub Actions, GitHub CLI.

**Spec:** `docs/superpowers/specs/2026-09-23-independent-release-design.md`

## Global Constraints

- Release version: `1.0.0`; tag: `v1.0.0`; slug: `influxdb`.
- Repository: `https://github.com/kitos9112/addon-influxdb`; supported architectures: `amd64` and `aarch64`.
- Keep InfluxDB Core, Enterprise, and Explorer as local-build upstream dependencies; do not publish their assembled image.
- Preserve the inherited MIT copyright notice and add `Copyright (c) 2026 Marcos Soutullo` for current contributions.
- No `image` key in `influxdb/config.yaml`; no `packages: write`, image push, or manifest publication in the release workflow.
- Keep `/data/influxdb3` and `/data/explorer` behavior and the `local_influxdb` migration warning.

## Review Focus

- A stray `image` key, even `image: null`, must fail the release contract instead of causing Supervisor to pull an unavailable image.
- A mismatched `v1.0.1` tag must fail before the GitHub release is created.
- A missing architecture must fail metadata validation.
- A tag outside `main` must fail before the GitHub release job.
- A release workflow with an image-publish job or package-write permission must fail the workflow contract test.

---

### Task 1: Switch add-on metadata to local builds

**Files:** Modify `tests/test-release-contract.rb`, `tests/check-release-contract.rb`, `influxdb/config.yaml`.

**Interfaces:** `check-release-contract.rb CONFIG_PATH [TAG]` prints a valid version, rejects an `image` key, and rejects mismatched tags. CI and the release workflow consume this result.

- [ ] **Step 1: Write failing tests.** Change the default fixture to version `1.0.0` without `image`, expect `"1.0.0\n"`, and assert that both `image: ghcr.io/kitos9112/addon-influxdb` and `image: null` fail with an image error. Keep mismatched-tag, invalid-version, and missing-architecture tests, adjusted to `v1.0.1`.

  ```ruby
  def test_image_key_fails_even_when_null
    ["image: ghcr.io/kitos9112/addon-influxdb", "image: null"].each do |image_line|
      _, stderr, status = check(config + "#{image_line}\n")
      refute status.success?
      assert_match(/image/, stderr)
    end
  end
  ```
- [ ] **Step 2: Verify RED.** Run `rtk ruby tests/test-release-contract.rb`; expect valid metadata to fail on the existing mandatory-image check.
- [ ] **Step 3: Implement.** Change the script to `abort "image must be omitted for local builds" if config.key?("image")`; set `version: 1.0.0` and remove `image` from `influxdb/config.yaml`.

  ```ruby
  abort "image must be omitted for local builds" if config.key?("image")
  ```
- [ ] **Step 4: Verify GREEN.** Run `rtk ruby tests/test-release-contract.rb` and `rtk ruby tests/check-release-contract.rb influxdb/config.yaml v1.0.0`; expect all tests green and `1.0.0`.
- [ ] **Step 5: Commit.** Commit only the three files as `feat: prepare local-build v1 metadata`.

### Task 2: Make the tag workflow publish source only

**Files:** Modify `tests/test-release-contract.rb`, `.github/workflows/release.yaml`.

**Interfaces:** Tag `v<version>` invokes `verify`, then reusable `ci`, then `github-release`; the last job has `contents: write` and no job has package-write permission.

- [ ] **Step 1: Write failing workflow tests.** Parse `.github/workflows/release.yaml` with `YAML.safe_load`, assert exactly `verify`, `ci`, and `github-release` job keys; assert `github-release.needs` contains `verify` and `ci`; assert no root or job `permissions` contains `packages` or `id-token`; assert the GitHub release job alone has `contents: write`.

  ```ruby
  workflow = YAML.safe_load(File.read(File.expand_path("../.github/workflows/release.yaml", __dir__)))
  jobs = workflow.fetch("jobs")
  assert_equal %w[ci github-release verify], jobs.keys.sort
  assert_equal %w[ci verify], jobs.fetch("github-release").fetch("needs").sort
  assert_equal "write", jobs.fetch("github-release").fetch("permissions").fetch("contents")
  ([workflow] + jobs.values).each do |scope|
    refute scope.fetch("permissions", {}).key?("packages")
    refute scope.fetch("permissions", {}).key?("id-token")
  end
  ```
- [ ] **Step 2: Verify RED.** Run `rtk ruby tests/test-release-contract.rb`; expect the exact-jobs assertion to fail because `matrix`, `build`, and `manifest` still exist.
- [ ] **Step 3: Implement.** Remove `matrix`, `build`, and `manifest` jobs from `release.yaml`; change `github-release.needs` to `[verify, ci]`. Keep tag/version and `main` ancestry gates and `gh release create --verify-tag`.
- [ ] **Step 4: Verify GREEN.** Run the Ruby tests, `rtk podman run --rm -v "$PWD:/repo" -w /repo docker.io/rhysd/actionlint:1.7.12`, and `rtk yamllint -d '{extends: default, rules: {line-length: disable, document-start: disable}}' repository.yaml influxdb/config.yaml .github`; expect no failures.
- [ ] **Step 5: Commit.** Commit the workflow and tests as `ci: release source without publishing images`.

### Task 3: Finish license and installation documentation

**Files:** Modify `LICENSE.md`, `README.md`, `influxdb/DOCS.md`, `influxdb/Dockerfile`, and mark `docs/superpowers/plans/2026-09-23-independent-release.md` superseded.

**Interfaces:** Users are told to add the repository, expect a local build and upstream registry downloads, keep their existing add-on separate, and observe upstream component licenses. The Dockerfile no longer labels the assembled image as wholly MIT.

- [ ] **Step 1: Review the existing local attribution edits.** Keep both the inherited and current copyright lines in `LICENSE.md`; confirm no upstream binary is checked into the repository.
- [ ] **Step 2: Update installation and release prose.** Replace GHCR availability/publish instructions with local-build timing, resource, upstream dependency, and licensing caveats; state GitHub release is source only. Make the same install expectation clear in `influxdb/DOCS.md`.
- [ ] **Step 3: Mark old plan superseded.** Add a one-line link to this source-only plan at the top of the earlier GHCR plan without rewriting its history.
- [ ] **Step 4: Verify.** Run `rtk git diff --check`, the Ruby tests, the ingress test, ShellCheck, YAML lint, and Actionlint locally; confirm Hadolint and both architecture builds in GitHub CI after pushing.
- [ ] **Step 5: Commit.** Commit the docs/license changes as `docs: document source-only v1 release and licenses`.

### Task 4: Publish and verify v1.0.0

**Files:** No product files unless CI reveals a defect.

**Interfaces:** `main` contains the verified implementation; the remote `v1.0.0` tag points to it; GitHub has a published source-only release; no GHCR package is created.

- [ ] **Step 1: Push `main`.** Verify the local commits and working tree, push to `origin/main`, and wait for CI `checks`, `amd64`, and `aarch64` to pass.
- [ ] **Step 2: Preserve inherited tag.** Confirm remote has no `v1.0.0`; save the inherited local `v1.0.0` commit under `legacy/v1.0.0`, then replace only the local `v1.0.0` tag with an annotated tag at the verified `main` commit.
- [ ] **Step 3: Publish.** Push only the new `v1.0.0` tag and wait for release workflow verification and GitHub release creation.
- [ ] **Step 4: Verify.** Confirm remote tag and release target the same commit, the release is public and source-only, no package was published, and `git status --short` is clean.
