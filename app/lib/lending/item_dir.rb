require 'lending/tileizer'

module Lending
  class ItemDir

    DIRNAME_RE = /(?<record_id>b?[0-9]{8,}+)_(?<barcode>.+)/.freeze
    MSG_BAD_DIRNAME = 'Item directory %s should be in the form <record_id>_<barcode>'.freeze

    attr_reader :path
    attr_reader :pages
    attr_reader :record_id
    attr_reader :barcode

    def initialize(dir:)
      @path = Tileizer.ensure_dirpath(dir)
      @record_id, @barcode = decompose_dirname(path)

      @pages = path.children.filter_map { |f| Page.new(f) if Tileizer.tiff?(f) }
    end

    def process_to(output_dir)
      output_dir_path = Tileizer.ensure_dirpath(output_dir)
      output_pages = pages.map { |page| page.process_to(output_dir_path) }
      ItemDir.allocate.tap do |dir|
        dir.instance_eval do
          @path = output_dir_path
          @pages = output_pages
        end
      end
    end

    private

    def decompose_dirname(path)
      name = path.basename.to_s
      raise ArgumentError, format(MSG_BAD_DIRNAME, path) unless (match_data = DIRNAME_RE.match(name))

      %i[record_id barcode].map { |f| match_data[f] }
    end
  end
end
