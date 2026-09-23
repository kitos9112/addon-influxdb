#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

config_path = ARGV.fetch(0, "influxdb/config.yaml")
expected_tag = ARGV[1]
config = YAML.safe_load(File.read(config_path))

abort "version must be MAJOR.MINOR.PATCH" unless config.fetch("version", nil).to_s.match?(/\A\d+\.\d+\.\d+\z/)
abort "image must be the standalone repository image" unless config["image"] == "ghcr.io/kitos9112/addon-influxdb"
abort "url must point to this repository" unless config["url"] == "https://github.com/kitos9112/addon-influxdb"
abort "arch must contain amd64 and aarch64" unless config["arch"].is_a?(Array) && config["arch"].sort == %w[aarch64 amd64]

version = config.fetch("version")
abort "tag #{expected_tag} does not match v#{version}" if expected_tag && expected_tag != "v#{version}"

puts version
