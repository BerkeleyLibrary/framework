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
      @infile_path = ensure_filepath(infile)
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

      def tileize(infile_path, outfile_path, fail_fast: false)
        Tileizer.new(infile_path, outfile_path).tap do |tileizer|
          logger.info("Tileizing #{infile_path} to #{outfile_path}")
          tileizer.tileize!
        rescue TileizeFailed => e
          logger.error(e)
          raise if fail_fast
        end
      end

      # Invokes either #tileize or #tileize_all based on environment
      # variables $INFILE and $OUTFILE.
      def tileize_env
        raise ArgumentError, "$#{ENV_INFILE} not set" if (infile = ENV[ENV_INFILE]).blank?
        raise ArgumentError, "$#{ENV_OUTFILE} not set" if (outfile = ENV[ENV_OUTFILE]).blank?

        if File.directory?(infile)
          tileize_all(infile, outfile)
        else
          tileize(infile, outfile, fail_fast: true)
        end
      end

      private

      def ensure_dirpath(dir)
        raise ArgumentError, "Not a directory: #{dir.inspect}" unless dir && File.directory?(dir.to_s)

        Pathname.new(dir.to_s)
      end

      def tiff?(pathname)
        pathname.file? && pathname.extname =~ /\.tiff?/
      end
    end

    private

    def ensure_filepath(f)
      raise ArgumentError, "Not a file path: #{f}" unless f && File.file?(f.to_s)

      Pathname.new(f.to_s)
    end

    def ensure_file_or_missing(f)
      return ensure_filepath(f) if File.exist?(f.to_s)

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
