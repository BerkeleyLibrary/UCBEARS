#!/usr/bin/env ruby

# Silence VIPS warnings -- see config/initializers/vips_logging
ENV['VIPS_LOGGING'] = '1'

# Don't buffer stdout or stderr
$stdout.sync = true
$stderr.sync = true

# Require gems
require 'bundler/setup'
require_relative '_zeitwerk'

# Run collector
collector = Lending::Collector.from_environment
collector.collect!
