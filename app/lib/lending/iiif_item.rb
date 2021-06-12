require 'lending/tileizer'
require 'ucblit/util/uris'

module Lending
  class IIIFItem

    MANIFEST_NAME = 'manifest.json'.freeze
    DIRNAME_RE = /(?<record_id>b?[0-9]{8,}+)_(?<barcode>.+)/.freeze
    MSG_BAD_DIRNAME = 'Item directory %s should be in the form <record_id>_<barcode>'.freeze

    attr_reader :title
    attr_reader :author
    attr_reader :dir_path
    attr_reader :pages
    attr_reader :record_id
    attr_reader :barcode

    def initialize(title:, author:, dir_path:)
      @title = title
      @author = author
      @dir_path = Tileizer.ensure_dirpath(dir_path)
      @record_id, @barcode = decompose_dirname(@dir_path)
      @pages = Page.all_from_directory(dir_path)
    end

    def dir_basename
      "#{record_id}_#{barcode}"
    end

    class << self
      include UCBLIT::Util::Logging

      def create_from(source_dir, output_dir, title:, author:)
        logger.info("Creating IIIF directory #{output_dir} from #{source_dir}")

        # TODO: use a temp directory
        source_dir_path = Tileizer.ensure_dirpath(source_dir)
        output_dir_path = Tileizer.ensure_dirpath(output_dir)
        tileize_pages(source_dir_path, output_dir_path)
        copy_page_texts(source_dir_path, output_dir_path)

        IIIFItem.new(title: title, author: author, dir_path: output_dir_path)
      end

      private

      def tileize_pages(source_dir_path, output_dir_path)
        source_dir_path.children.each do |f|
          Tileizer.tileize(f, output_dir_path) if page_tiff?(f)
        end
      end

      def copy_page_texts(source_dir_path, output_dir_path)
        source_dir_path.children.each do |f|
          next unless page_tiff?(f) && (txt_path = Page.txt_path_from(f))

          output_txt_path = output_dir_path.join(txt_path.basename)
          FileUtils.cp(txt_path, output_txt_path)
        end
      end

      def page_tiff?(f)
        Tileizer.tiff?(f) && Page.page_number?(f)
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def to_manifest(manifest_root_uri, image_root_uri)
      manifest_uri = UCBLIT::Util::URIs.append(manifest_root_uri, dir_basename)
      image_dir_uri = UCBLIT::Util::URIs.append(image_root_uri, dir_basename)

      IIIF::Presentation::Manifest.new.tap do |mf|
        mf['@id'] = manifest_uri
        mf.label = title
        mf.metadata << md(Title: title)
        mf.metadata << md(Author: author)
        mf.sequences << IIIF::Presentation::Sequence.new.tap do |seq|
          pages.each do |page|
            seq << page.to_canvas(manifest_uri, image_dir_uri)
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def write_manifest!(manifest_root_uri, image_root_uri)
      manifest = to_manifest(manifest_root_uri, image_root_uri)
      manifest_json = manifest.to_json
      dir_path.join(MANIFEST_NAME).tap do |manifest_path|
        manifest_path.open('w') { |f| f.write(manifest_json) }
      end
    end

    private

    def decompose_dirname(path)
      match_data = DIRNAME_RE.match(path.basename.to_s)
      raise ArgumentError, format(MSG_BAD_DIRNAME, path) unless match_data

      %i[record_id barcode].map { |f| match_data[f] }
    end

    # TODO: share code w/Page
    def md(**kvp)
      return kvp.map { |k, v| { label: k, value: v } } if kvp.size == 1

      raise ArgumentError("Metadata entry #{kvp.inspect} should be of the form {label: value}")
    end
  end
end
