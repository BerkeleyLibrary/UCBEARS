#!/usr/bin/env ruby

# Don't buffer stdout or stderr
$stdout.sync = true
$stderr.sync = true

# Require gems
require 'bundler/setup'

# Require lib/lending
unless $LOAD_PATH.include?((lib_path = File.expand_path('../../lib', __dir__)))
  puts "Adding #{lib_path} to $LOAD_PATH"
  $LOAD_PATH.unshift(lib_path)
end
require 'lending'

# Run collector
collector = Lending::Collector.from_environment
collector.collect!
