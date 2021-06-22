require 'pathname'

module Lending
  module PathUtils
    def ensure_pathname(p)
      p.is_a?(Pathname) ? p : Pathname.new(p.to_s)
    end

    def ensure_filepath(f)
      raise ArgumentError, "Not a file path: #{f}" unless f && File.file?(f.to_s)

      ensure_pathname(f)
    end

    def ensure_dirpath(dir)
      raise ArgumentError, "Not a directory: #{dir.inspect}" unless dir && File.directory?(dir.to_s)

      ensure_pathname(dir)
    end

    def ensure_non_directory(f)
      ensure_pathname(f).tap do |pathname|
        return ensure_filepath(pathname) if pathname.exist?
      end
    end

    def stem(p)
      path = ensure_pathname(p)
      path.basename(path.extname).to_s
    end

    def tiff?(p)
      pathname = ensure_pathname(p)
      pathname.file? && pathname.extname =~ /\.tiff?/
    end

    def txt_path_from(tiff_path)
      txt_path = tiff_path.parent.join("#{stem(tiff_path)}.txt")
      txt_path if txt_path.file?
    end

    def env_path(varname)
      raise ArgumentError, "$#{varname} not set" if (val = ENV[varname]).blank?

      ensure_pathname(val)
    end

    class << self
      include PathUtils
    end
  end
end
