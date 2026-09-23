#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "yaml"

class ReleaseContractTest < Minitest::Test
  SCRIPT = File.expand_path("check-release-contract.rb", __dir__)

  def config(version: "1.0.0")
    <<~YAML
      name: InfluxDB 3
      version: #{version}
      slug: influxdb
      url: https://github.com/kitos9112/addon-influxdb
      arch:
        - amd64
        - aarch64
    YAML
  end

  def check(contents, *args)
    Dir.mktmpdir do |directory|
      path = File.join(directory, "config.yaml")
      File.write(path, contents)
      return Open3.capture3("ruby", SCRIPT, path, *args)
    end
  end

  def test_valid_metadata
    stdout, stderr, status = check(config)
    assert status.success?, stderr
    assert_equal "1.0.0\n", stdout
  end

  def test_wrong_tag_fails
    _, stderr, status = check(config, "v1.0.1")
    refute status.success?
    assert_match(/does not match/, stderr)
  end

  def test_image_key_fails_even_when_null
    ["image: ghcr.io/kitos9112/addon-influxdb", "image: null"].each do |image_line|
      _, stderr, status = check(config + "#{image_line}\n")
      refute status.success?
      assert_match(/image/, stderr)
    end
  end

  def test_unpublishable_version_fails
    _, stderr, status = check(config(version: "dev"))
    refute status.success?
    assert_match(/version/, stderr)
  end

  def test_missing_architecture_fails
    _, stderr, status = check(config.sub("  - aarch64\n", ""))
    refute status.success?
    assert_match(/arch/, stderr)
  end

  def test_release_workflow_publishes_source_only_after_ci
    path = File.expand_path("../.github/workflows/release.yaml", __dir__)
    workflow = YAML.safe_load(File.read(path))
    jobs = workflow.fetch("jobs")

    assert_equal %w[ci github-release verify], jobs.keys.sort
    assert_equal %w[ci verify], jobs.fetch("github-release").fetch("needs").sort
    assert_equal "write", jobs.fetch("github-release").fetch("permissions").fetch("contents")
    ([workflow] + jobs.values).each do |scope|
      refute scope.fetch("permissions", {}).key?("packages")
      refute scope.fetch("permissions", {}).key?("id-token")
    end
  end
end
