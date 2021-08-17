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
infile, outfile = ARGV
[infile, outfile].each { |d| raise ArgumentError, "#{d}: No such file or directory" unless File.exist?(d) }

if File.directory?(outfile)
  Lending::Tileizer.tileize_all(infile, outfile, skip_existing: true)
else
  Lending::Tileizer.tileize(infile, outfile)
end
