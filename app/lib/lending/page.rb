require 'lending/tileizer'
require 'iiif/presentation'
require 'ucblit/util/uris'

module Lending
  class Page
    include Comparable

    attr_reader :tiff_path
    attr_reader :basename
    attr_reader :stem
    attr_reader :number
    attr_reader :txt_path

    def initialize(tiff_path)
      @tiff_path = Tileizer.ensure_filepath(tiff_path)
      raise ArgumentError, 'Not a TIFF file' unless Tileizer.tiff?(@tiff_path)

      @basename = @tiff_path.basename.to_s
      @stem = @tiff_path.basename(tiff_path.extname)
      @number = Integer(stem.to_s, 10)
      @txt_path = Page.txt_path_from(@tiff_path)
    end

    class << self
      DIGITS_RE = /^\d+$/.freeze

      def page_number?(path)
        path.basename(path.extname).to_s =~ DIGITS_RE
      end

      def txt_path_from(tiff_path)
        stem = tiff_path.basename(tiff_path.extname)
        txt_path = tiff_path.parent.join("#{stem}.txt")
        txt_path if txt_path.file?
      end

      def all_from_directory(dir)
        dirpath = Tileizer.ensure_dirpath(dir)
        dirpath.children.filter_map do |f|
          next unless Tileizer.tiff?(f) && Page.page_number?(f)

          Page.new(f)
        end
      end

      private

      def ensure_page_tiff_path(path)
        Tileizer.ensure_filepath(path).tap do |tiff_path|
          raise ArgumentError, "Not a TIFF file: #{tiff_path}" unless Tileizer.tiff?(tiff_path)
          raise ArgumentError, "Not a numeric page number: #{tiff_path}" unless page_number?(tiff_path)
        end
      end
    end

    def image
      @image ||= Vips::Image.new_from_file(tiff_path.to_s)
    end

    def width
      image.width
    end

    def height
      image.height
    end

    def <=>(other)
      return unless other.class == self.class
      return 0 if equal?(other)

      order = number <=> other.order
      return order if order != 0

      tiff_path <=> other.tiff_path
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def to_canvas(manifest_uri, image_dir_uri)
      canvas_uri = UCBLIT::Util::URIs.append(manifest_uri, "canvas/p#{number}")
      tiff_uri = UCBLIT::Util::URIs.append(image_dir_uri, basename)
      IIIF::Presentation::Canvas.new.tap do |canvas|
        canvas['@id'] = canvas_uri
        canvas.label = "Page #{number}"
        canvas.height = height
        canvas.width = width
        canvas.images << IIIF::Presentation::Annotation.new.tap do |a8n|
          a8n['on'] = canvas_uri
          a8n.resource = IIIF::Presentation::ImageResource.new.tap do |rsrc|
            rsrc['@id'] = tiff_uri
            rsrc.format = 'image/tiff'
            # TODO: rsrc.service?
            rsrc.height = height
            rsrc.width = width
          end
        end
        # TODO: does this work?
        canvas.metadata << { Transcript: File.read(txt_path) } if txt_path
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  end
end
