require 'lending/tileizer'

module Lending
  class IIIFItem

    DIRNAME_RE = /(?<record_id>b?[0-9]{8,}+)_(?<barcode>.+)/.freeze
    MSG_BAD_DIRNAME = 'Item directory %s should be in the form <record_id>_<barcode>'.freeze

    attr_reader :dir_path
    attr_reader :pages
    attr_reader :record_id
    attr_reader :barcode

    def initialize(dir_path:, record_id:, barcode:, pages:)
      @dir_path = dir_path
      @record_id = record_id
      @barcode = barcode
      @pages = pages
    end

    class << self
      def create_from(source_dir, output_dir)
        # TODO: use a temp directory
        source_dir_path = Tileizer.ensure_dirpath(source_dir)
        output_dir_path = Tileizer.ensure_dirpath(output_dir)
        record_id, barcode = decompose_dirname(source_dir_path)
        IIIFItem.new(
          dir_path: output_dir_path,
          record_id: record_id,
          barcode: barcode,
          pages: create_pages(source_dir_path, output_dir_path)
        )
      end

      private

      def create_pages(source_dir_path, output_dir_path)
        source_dir_path.children.filter_map do |f|
          next unless Tileizer.tiff?(f) && Page.page_number?(f)

          Page.create_from(tiff_path, output_dir_path)
        end
      end

      def decompose_dirname(path)
        name = path.basename.to_s
        raise ArgumentError, format(MSG_BAD_DIRNAME, path) unless (match_data = DIRNAME_RE.match(name))

        %i[record_id barcode].map { |f| match_data[f] }
      end
    end
  end
end
