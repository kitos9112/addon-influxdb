#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"

class ReleaseContractTest < Minitest::Test
  SCRIPT = File.expand_path("check-release-contract.rb", __dir__)

  def config(version: "7.0.0", image: "ghcr.io/kitos9112/addon-influxdb")
    <<~YAML
      name: InfluxDB 3
      version: #{version}
      slug: influxdb
      url: https://github.com/kitos9112/addon-influxdb
      image: #{image}
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
    assert_equal "7.0.0\n", stdout
  end

  def test_wrong_tag_fails
    _, stderr, status = check(config, "v7.0.1")
    refute status.success?
    assert_match(/does not match/, stderr)
  end

  def test_inherited_or_missing_image_fails
    ["ghcr.io/someone-else/addon-influxdb", ""].each do |image|
      _, stderr, status = check(config(image: image))
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
end
