#!/usr/bin/env ruby

# Require gems
require_relative '_zeitwerk'

# Parse arguments
infile, outfile = ARGV
[infile, outfile].each { |d| raise ArgumentError, "#{d}: No such file or directory" unless File.exist?(d) }

if File.directory?(outfile)
  Lending::Tileizer.tileize_all(infile, outfile, skip_existing: true)
else
  Lending::Tileizer.tileize(infile, outfile)
end
