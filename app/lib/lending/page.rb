require 'lending/tileizer'
require 'iiif/presentation'
require 'ucblit/util/uris'

module Lending
  class Page
    include Comparable

    # TODO: make this configurable
    VIEW_W = 1024
    # TODO: make this configurable
    VIEW_H = 1024

    SCALED_IMAGE_FMT = 'image/jpeg'.freeze

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

    def tiles
      @tiles ||= (0...image.get('n-pages')).map { |p| Vips::Image.new_from_file(tiff_path.to_s, page: p) }
    end

    def tile_scale_factors
      @tile_scale_factors ||= tiles.map { |t| width / t.width }.sort
    end

    def width
      @width ||= image.width
    end

    def height
      @height ||= image.height
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
      canvas_uri = canvas_uri_for(manifest_uri)
      tiff_uri = tiff_uri_for(image_dir_uri)
      IIIF::Presentation::Canvas.new.tap do |canvas|
        canvas['@id'] = canvas_uri
        canvas.label = "Page #{number}"
        canvas.width = width
        canvas.height = height
        canvas.images << IIIF::Presentation::Annotation.new.tap do |a8n|
          a8n['on'] = canvas_uri
          a8n['@id'] = annotation_id_for(tiff_uri)

          resource_id = resource_id_for(tiff_uri)
          service_id = tiff_uri # TODO: is this right?
          a8n.resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
            resource_id: resource_id,
            service_id: service_id,
            format: SCALED_IMAGE_FMT,
            width: width,
            height: height,
            profile: 'http://iiif.io/api/image/2/level1.json',
            sizes: tiles.map { |page| { width: page.width, height: page.height } },
            tiles: [
              {
                width: 256, # TODO: why is this 256?
                height: 256, # TODO: why is this 256?
                scaleFactors: tile_scale_factors
              }
            ]
          )
        end
        # TODO: does this work?
        add_metadata(canvas, Transcript: File.read(txt_path)) if txt_path
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    def canvas_uri_for(manifest_uri)
      UCBLIT::Util::URIs.append(manifest_uri, "canvas/p#{number}")
    end

    def tiff_uri_for(image_dir_uri)
      UCBLIT::Util::URIs.append(image_dir_uri, basename)
    end

    def annotation_id_for(manifest_uri)
      UCBLIT::Util::URIs.append(manifest_uri, "annotation/p#{number}-image")
    end

    def resource_id_for(tiff_uri)
      UCBLIT::Util::URIs.append(tiff_uri, "/full/!#{VIEW_W},#{VIEW_H}/0/default.jpg")
    end

    # # TODO: something less clunky
    # def scale_for_viewport
    #   @scale_for_viewport ||= begin
    #     w_ratio = VIEW_W.to_f / width
    #     h_ratio = VIEW_H.to_f / height
    #     [w_ratio, h_ratio].min
    #   end
    # end
    #
    # def scaled_width
    #   @scaled_width ||= (width * scale_for_viewport).to_i
    # end
    #
    # def scaled_height
    #   @scaled_height ||= (height * scale_for_viewport).to_i
    # end

    # TODO: share code between Page and IIIFItem
    def add_metadata(resource, **md)
      md.each { |k, v| resource.metadata << { label: k, value: v } }
    end

  end
end
