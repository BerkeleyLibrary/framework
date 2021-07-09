#!/usr/bin/env ruby

# Require gems
require 'bundler/setup'

# Require lib/lending
unless $LOAD_PATH.include?((lib_path = File.expand_path('../../lib', __dir__)))
  puts "Adding #{lib_path} to $LOAD_PATH"
  $LOAD_PATH.unshift(lib_path)
end
require 'lending'

# Parse environment
lending_root, interval = [Lending::ENV_ROOT, Lending::ENV_COLLECTOR_INTERVAL].map do |v|
  ENV[v].tap do |value|
    raise ArgumentError, "$#{v} is unset or blank" if value.blank?
  end
end

# Run collector
Lending::Collector.new(lending_root, interval.to_r).collect!
