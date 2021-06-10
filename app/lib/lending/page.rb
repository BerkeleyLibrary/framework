require 'lending/tileizer'

module Lending
  class Page
    include Comparable

    attr_reader :basename
    attr_reader :number
    attr_reader :tiff_path
    attr_reader :txt_path

    def initialize(tiff_path)
      @tiff_path = Tileizer.ensure_filepath(tiff_path)
      raise ArgumentError, 'Not a TIFF file' unless Tileizer.tiff?(@tiff_path)

      @basename = @tiff_path.basename(tiff_path.extname)
      @number = Integer(basename, 10)
      @txt_path = txt_path_from(@tiff_path)
    end

    def <=>(other)
      return unless other.class == self.class
      return 0 if equal?(other)

      order = number <=> other.order
      return order if order != 0

      tiff_path <=> other.tiff_path
    end

    def process_to(output_dir)
      output_dir_path = Tileizer.ensure_dirpath(output_dir)
      output_tiff_path = output_dir_path.join("#{basename}.tif")
      Tileizer.tileize(tiff_path, output_tiff_path)

      if txt_path
        output_txt_path = output_dir_path.join("#{basename}.txt")
        FileUtils.cp(txt_path, output_txt_path)
      end

      Page.new(output_tiff_path)
    end

    private

    def txt_path_from(tiff_path)
      txt_path = tiff_path.parent.join("#{basename}.txt")
      txt_path if txt_path.file?
    end

  end
end
