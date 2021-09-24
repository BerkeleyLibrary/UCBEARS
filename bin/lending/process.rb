#!/usr/bin/env ruby

# Don't buffer stdout or stderr
$stdout.sync = true
$stderr.sync = true

# Require gems
require 'bundler/setup'
require_relative '_zeitwerk'

# Parse arguments
indir, outdir = ARGV
[indir, outdir].each { |d| raise ArgumentError, "Not a directory: #{d}" unless File.directory?(d) }

# Process
Lending::Processor.new(indir, outdir).process!
