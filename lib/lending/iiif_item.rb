require 'lending/tileizer'
require 'lending/page'
require 'ucblit/util/uris'

module Lending
  # TODO: rename this to IIIFManifest, #to_manifest to #to_json_str or something
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
      @dir_path = PathUtils.ensure_dirpath(dir_path)
      @record_id, @barcode = decompose_dirname(@dir_path)
      @pages = Page.all_from_directory(dir_path)
    end

    def dir_basename
      "#{record_id}_#{barcode}"
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create_manifest(manifest_uri, image_root_uri)
      dir_basename_encoded = ERB::Util.url_encode(dir_basename)
      image_dir_uri = UCBLIT::Util::URIs.append(image_root_uri, dir_basename_encoded)

      IIIF::Presentation::Manifest.new.tap do |mf|
        mf['@id'] = manifest_uri
        mf.label = title
        add_metadata(mf, Title: title, Author: author)
        mf.sequences << IIIF::Presentation::Sequence.new.tap do |seq|
          pages.each do |page|
            seq.canvases << page.to_canvas(manifest_uri, image_dir_uri)
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    # TODO: share code between Page and IIIFItem
    def add_metadata(resource, **md)
      md.each { |k, v| resource.metadata << { label: k, value: v } }
    end

    def decompose_dirname(path)
      # TODO: what about check digits?
      match_data = DIRNAME_RE.match(path.basename.to_s)
      raise ArgumentError, format(MSG_BAD_DIRNAME, path) unless match_data

      %i[record_id barcode].map { |f| match_data[f] }
    end
  end
end
