#!/usr/bin/env ruby

# Require gems
require 'bundler/setup'

# Require lib/lending
unless $LOAD_PATH.include?((lib_path = File.expand_path('../../lib', __dir__)))
  puts "Adding #{lib_path} to $LOAD_PATH"
  $LOAD_PATH.unshift(lib_path)
end
require 'lending'

# Parse arguments
indir, outdir = ARGV
[indir, outdir].each { |d| raise ArgumentError, "Not a directory: #{d}" unless File.directory?(d) }

# Process
Lending::Processor.new(indir, outdir).process!
