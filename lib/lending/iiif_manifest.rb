require 'lending/tileizer'
require 'lending/page'
require 'ucblit/util/uris'

module Lending
  class IIIFManifest
    include UCBLIT::Logging

    MANIFEST_NAME = 'manifest.json'.freeze
    DIRNAME_RE = /(?<record_id>b?[0-9]{8,}+)_(?<barcode>.+)/.freeze
    MSG_BAD_DIRNAME = 'Item directory %s should be in the form <record_id>_<barcode>'.freeze

    MF_TAG = '<%= manifest_uri %>'.freeze
    IMG_TAG = '<%= image_dir_uri %>'.freeze

    MF_URL_PLACEHOLDER = 'https://ucbears.invalid/manifest'.freeze
    IMGDIR_URL_PLACEHOLDER = 'https://ucbears.invalid/imgdir'.freeze

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

    # noinspection RubyUnusedLocalVariable
    def json_manifest(manifest_uri, image_root_uri)
      image_dir_uri = UCBLIT::Util::URIs.append(
        image_root_uri,
        ERB::Util.url_encode(dir_basename)
      )

      # depends on: manifest_uri, image_dir_uri
      template.result(binding)
    end

    def to_erb
      create_manifest(MF_URL_PLACEHOLDER, IMGDIR_URL_PLACEHOLDER)
        .to_json(pretty: true)
        .gsub(MF_URL_PLACEHOLDER, MF_TAG)
        .gsub(IMGDIR_URL_PLACEHOLDER, IMG_TAG)
    end

    private

    def template
      @template ||= ERB.new(erb_source)
    end

    def erb_source
      @erb_source ||= erb_path.file? ? erb_path.read : write_erb
    end

    def erb_path
      @erb_path ||= dir_path.join('manifest.json.erb')
    end

    def write_erb
      logger.info("Writing #{erb_path}")
      to_erb.tap { |erb| File.write(erb_path.to_s, erb) }
    end

    # rubocop:disable Metrics/AbcSize
    def create_manifest(manifest_uri, image_dir_uri)
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
    # rubocop:enable Metrics/AbcSize

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
