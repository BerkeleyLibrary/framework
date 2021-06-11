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
      @txt_path = Page.txt_path_from(@tiff_path)
    end

    class << self
      DIGITS_RE = /^\d+$/.freeze

      def create_from(tiff_path, output_dir)
        input_tiff_path = ensure_page_tiff_path(tiff_path)
        basename = input_tiff_path.basename(input_tiff_path.extname)

        output_dir_path = Tileizer.ensure_dirpath(output_dir)
        output_tiff_path = output_dir_path.join("#{basename}.tif")
        Tileizer.tileize(input_tiff_path, output_tiff_path)

        if (txt_path = txt_path_from(input_tiff_path))
          output_txt_path = output_dir_path.join("#{basename}.txt")
          FileUtils.cp(txt_path, output_txt_path)
        end

        Page.new(output_tiff_path)
      end

      def page_number?(path)
        path.basename(path.extname) =~ DIGITS_RE
      end

      def txt_path_from(tiff_path)
        txt_path = tiff_path.parent.join("#{basename}.txt")
        txt_path if txt_path.file?
      end

      private

      def ensure_page_tiff_path(path)
        Tileizer.ensure_filepath(path).tap do |tiff_path|
          raise ArgumentError, "Not a TIFF file: #{tiff_path}" unless Tileizer.tiff?(tiff_path)
          raise ArgumentError, "Not a numeric page number: #{tiff_path}" unless page_number?(tiff_path)
        end
      end
    end

    def <=>(other)
      return unless other.class == self.class
      return 0 if equal?(other)

      order = number <=> other.order
      return order if order != 0

      tiff_path <=> other.tiff_path
    end

  end
end
