#!/usr/bin/env ruby

# Require gems
require 'bundler/setup'

# Require lib/lending
unless $LOAD_PATH.include?((lib_path = File.expand_path('../lib', __dir__)))
  puts "Adding #{lib_path} to $LOAD_PATH"
  $LOAD_PATH.unshift(lib_path)
end
require 'lending'

# Parse arguments
indir, outdir = ARGV
[indir, outdir].each { |d| raise ArgumentError, "Not a directory: #{d}" unless File.directory?(d) }

# Tileize files
Lending::Tileizer.tileize_all(indir, outdir, skip_existing: true)

# Copy OCR text
# TODO: put this in a library method and test it
outdir.entries.each do |outfile|
  next unless Lending::PathUtils.tiff_ext?(outfile)
  next if (outfile_txt = Lending::PathUtils.txt_path_from(outfile).to_s)

  infile_txt = File.join(indir, File.basename(outfile_txt))
  FileUtils.cp(infile_txt, outfile_txt)
end
