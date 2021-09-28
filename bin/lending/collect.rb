#!/usr/bin/env ruby

# Silence VIPS warnings -- see config/initializers/vips_logging
ENV['VIPS_LOGGING'] = '1'

# Don't buffer stdout or stderr
$stdout.sync = true
$stderr.sync = true

# Require gems
require 'bundler/setup'
require_relative '_zeitwerk'

# Debug VIPS memory leaks, maybe
require 'vips'
Vips.leak_set(true)
# Reduce VIPS memory usage? https://github.com/libvips/ruby-vips/issues/67#issuecomment-670201877
Vips::cache_set_max(0)

# Run collector
collector = Lending::Collector.from_environment
collector.collect!
