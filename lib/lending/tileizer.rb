require 'vips'
require 'pathname'
require 'ucblit/logging'
require 'lending/path_utils'

module Lending
  class Tileizer

    ENV_INFILE = 'INFILE'.freeze
    ENV_OUTFILE = 'OUTFILE'.freeze

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
      @outfile_path = PathUtils.ensure_non_directory(outfile)
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

      # ENV_INFILE = Tileizer::ENV_INFILE
      # ENV_OUTFILE = Tileizer::ENV_OUTFILE

      def tileize_all(indir, outdir)
        indir_path, outdir_path = [indir, outdir].map { |d| PathUtils.ensure_dirpath(d) }
        raise ArgumentError, "Can't write tileized files to same directory as input files" if indir_path == outdir_path

        infiles = indir_path.children.select { |p| PathUtils.tiff?(p) }.sort
        infiles.map do |infile_path|
          outfile_path = outdir_path.join(infile_path.basename)
          tileize(infile_path, outfile_path)
        end
      end

      # @param infile_path [String, Pathname] the input file path
      # @param outfile_path [String, Pathname] the output file or directory path. If a directory,
      #   the actual file will be created based on the input filename.
      def tileize(infile_path, outfile_path, fail_fast: false)
        infile_path, outfile_path = PathUtils.ensure_pathnames(infile_path, outfile_path)
        if outfile_path.directory?
          stem = infile_path.basename(infile_path.extname)
          outfile_path = outfile_path.join("#{stem}.tif")
        end
        outfile_path.tap { |op| tileize!(infile_path, op, fail_fast) }
      end

      # Invokes either #tileize or #tileize_all based on environment
      # variables $INFILE and $OUTFILE.
      def tileize_env
        infile, outfile = [ENV_INFILE, ENV_OUTFILE].map { |v| PathUtils.env_path(v) }
        return tileize_all(infile, outfile) if infile.directory?

        tileize(infile, outfile, fail_fast: true)
      end

      private

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

  class TileizeFailed < StandardError
    def initialize(infile_path, outfile_path, vips_options, cause:)
      msg = "Tileizing #{infile_path} to #{outfile_path} with options: "
      msg << vips_options.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
      msg << "failed with #{cause}"

      super(msg)
    end
  end
end
