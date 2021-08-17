require 'vips'
require 'pathname'
require 'ucblit/logging'
require 'lending/path_utils'
require 'lending/tileize_failed'

module Lending
  class Tileizer

    # vips tiffsave <infile> <outfile> --tile --pyramid --compression jpeg --tile-width 256 --tile-height 256
    VIPS_OPTIONS = {
      tile: true,
      pyramid: true,
      compression: 'jpeg',
      tile_width: 256,
      tile_height: 256,
      depth: 'onetile'
    }.freeze

    attr_reader :infile_path
    attr_reader :outfile_path

    def initialize(infile, outfile)
      @infile_path = PathUtils.ensure_filepath(infile)
      @outfile_path = PathUtils.ensure_non_directory(outfile).tap do |outfile_path|
        raise ArgumentError, "Not a TIFF file: #{outfile_path}" unless PathUtils.tiff_ext?(outfile_path)
      end
    end

    def tileized?
      @tileized ||= false
    end

    def tileize!
      source_img = Vips::Image.new_from_file(infile_path.to_s)
      source_img.tiffsave(outfile_path.to_s, **VIPS_OPTIONS)
      @tileized = true
    rescue StandardError => e
      raise TileizeFailed.new(infile_path, outfile_path, VIPS_OPTIONS, cause: e)
    end

    class << self
      include UCBLIT::Logging

      def tileize_all(indir, outdir, skip_existing: false, fail_fast: false)
        indir_path, outdir_path = [indir, outdir].map { |d| PathUtils.ensure_dirpath(d) }
        raise ArgumentError, "Can't write tileized files to same directory as input files" if indir_path == outdir_path

        infiles_from(indir_path).map do |infile_path|
          stem = infile_path.basename(infile_path.extname)
          outfile_path = outdir_path.join("#{stem}.tif")

          tileize(infile_path, outfile_path, skip_existing: skip_existing, fail_fast: fail_fast)
        end
      end

      # @param infile_path [String, Pathname] the input file path
      # @param outfile_path [String, Pathname] the output file or directory path. If a directory,
      #   the actual file will be created based on the input filename.
      def tileize(infile_path, outfile_path, skip_existing: false, fail_fast: false)
        infile_path, outfile_path = PathUtils.ensure_pathnames(infile_path, outfile_path)
        if outfile_path.directory?
          stem = infile_path.basename(infile_path.extname)
          outfile_path = outfile_path.join("#{stem}.tif")
        end
        if skip_existing && outfile_path.exist?
          logger.info("Skipping existing file #{outfile_path}")
          return
        end

        outfile_path.tap { |op| tileize!(infile_path, op, fail_fast) }
      end

      private

      def infiles_from(indir_path)
        infiles_by_stem = indir_path.children.each_with_object({}) do |p, by_stem|
          next unless PathUtils.image?(p)

          # Prefer TIFF to JPEG if both exist
          stem = PathUtils.stem(p)
          by_stem[stem] = p unless by_stem.key?(stem) && PathUtils.jpeg_ext?(p)
        end

        infiles_by_stem.values.sort
      end

      def tileize!(infile_path, outfile_path, fail_fast)
        Tileizer.new(infile_path, outfile_path).tap do |tileizer|
          logger.info("Tileizing #{infile_path} to #{outfile_path}")
          tileizer.tileize!
        rescue TileizeFailed => e
          logger.error(e)
          raise if fail_fast
        end
      end
    end

  end
end
