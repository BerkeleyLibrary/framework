require 'vips'
require 'pathname'
require 'ucblit/logging'

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
      @infile_path = Tileizer.ensure_filepath(infile)
      @outfile_path = ensure_file_or_missing(outfile)
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
        indir_path, outdir_path = [indir, outdir].map { |d| ensure_dirpath(d) }
        raise ArgumentError, "Can't write tileized files to same directory as input files" if indir_path == outdir_path

        infiles = indir_path.children.select { |p| tiff?(p) }.sort
        infiles.map do |infile_path|
          outfile_path = outdir_path.join(infile_path.basename)
          tileize(infile_path, outfile_path)
        end
      end

      # @param infile_path [Pathname] the input file path
      # @param outfile_path [Pathname] the output file or directory path. If a directory,
      #   the actual file will be created based on the input filename.
      def tileize(infile_path, outfile_path, fail_fast: false)
        if outfile_path.directory?
          stem = infile_path.basename(infile_path.extname)
          outfile_path = outfile_path.join("#{stem}.tif")
        end
        outfile_path.tap { |op| tileize!(infile_path, op, fail_fast) }
      end

      # Invokes either #tileize or #tileize_all based on environment
      # variables $INFILE and $OUTFILE.
      def tileize_env
        infile, outfile = [ENV_INFILE, ENV_OUTFILE].map { |v| env_path(v) }
        return tileize_all(infile, outfile) if infile.directory?

        tileize(infile, outfile, fail_fast: true)
      end

      # TODO: move this to UCBLIT::Util::Files or something
      def ensure_filepath(f)
        raise ArgumentError, "Not a file path: #{f}" unless f && File.file?(f.to_s)

        ensure_path(f)
      end

      # TODO: move this to UCBLIT::Util::Files or something
      def ensure_dirpath(dir)
        raise ArgumentError, "Not a directory: #{dir.inspect}" unless dir && File.directory?(dir.to_s)

        ensure_path(dir)
      end

      def tiff?(pathname)
        pathname.file? && pathname.extname =~ /\.tiff?/
      end

      private

      def env_path(varname)
        raise ArgumentError, "$#{varname} not set" if (val = ENV[varname]).blank?

        ensure_path(val)
      end

      def ensure_path(p)
        p.is_a?(Pathname) ? p : Pathname.new(p.to_s)
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

    private

    def ensure_file_or_missing(f)
      return Tileizer.ensure_filepath(f) if File.exist?(f.to_s)

      Pathname.new(f.to_s)
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
