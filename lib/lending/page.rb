require 'lending/path_utils'
require 'lending/tileizer'
require 'iiif/presentation'
require 'ucblit/util/uris'

module Lending
  # rubocop:disable Metrics/ClassLength
  class Page
    include Comparable

    # TODO: make this configurable
    VIEW_W = 1024
    # TODO: make this configurable
    VIEW_H = 1024

    SCALED_IMAGE_FMT = 'image/jpeg'.freeze

    attr_reader :tiff_path
    attr_reader :basename
    attr_reader :number
    attr_reader :txt_path

    def initialize(tiff_path)
      @tiff_path = ensure_page_tiff_path(tiff_path)
      @basename = @tiff_path.basename.to_s
      @number = Integer(PathUtils.stem(tiff_path), 10)
      @txt_path = PathUtils.txt_path_from(@tiff_path)
    end

    class << self
      DIGITS_RE = /^\d+$/.freeze

      def page_number?(path)
        PathUtils.stem(path) =~ DIGITS_RE
      end

      def all_from_directory(dir)
        dirpath = PathUtils.ensure_dirpath(dir)
        dirpath.children.filter_map do |f|
          next unless PathUtils.tiff_ext?(f) && Page.page_number?(f)

          Page.new(f)
        end.sort
      end

      def assert_equal!(p1, p2)
        page1, page2 = [p1, p2].map { |p| p.is_a?(Page) ? p : Page.new(p) }
        errors = %i[basename width height tile_scale_factors].each_with_object([]) do |attr, errs|
          v1, v2 = [page1, page2].map { |p| p.send(attr) }
          errs << "#{attr}: expected #{v1}, got #{v2}" unless v1 == v2
        end
        raise ArgumentError, "#{page1} != #{page2}: " + errors.join('; ') unless errors.empty?
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

      0.tap do
        break if equal?(other)

        %i[number tiff_path].each do |attr|
          order = send(attr) <=> other.send(attr)
          return order if order != 0
        end
      end
    end

    # rubocop:disable Metrics/AbcSize
    def to_canvas(manifest_uri, image_dir_uri)
      canvas_uri = canvas_uri_for(manifest_uri)
      tiff_uri = tiff_uri_for(image_dir_uri)
      IIIF::Presentation::Canvas.new.tap do |canvas|
        canvas['@id'] = canvas_uri
        canvas.label = "Page #{number}"
        canvas.width = width
        canvas.height = height
        canvas.images << create_image_annotation(canvas_uri, tiff_uri)
        # TODO: use :rendering
        add_metadata(canvas, Transcript: txt_path.read) if txt_path.exist?
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    def ensure_page_tiff_path(path)
      PathUtils.ensure_filepath(path).tap do |tiff_path|
        raise ArgumentError, "Not a TIFF file: #{tiff_path}" unless PathUtils.tiff_ext?(tiff_path)
        raise ArgumentError, "Not a numeric page number: #{tiff_path}" unless Page.page_number?(tiff_path)
      end
    end

    def create_image_annotation(canvas_uri, tiff_uri)
      IIIF::Presentation::Annotation.new.tap do |a8n|
        a8n['on'] = canvas_uri
        a8n['@id'] = annotation_id_for(tiff_uri)

        a8n.resource = create_image_resource(tiff_uri)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def create_image_resource(tiff_uri)
      IIIF::Presentation::ImageResource.create_image_api_image_resource(
        resource_id: resource_id_for(tiff_uri),
        service_id: tiff_uri, # TODO: is this right?
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
    # rubocop:enable Metrics/MethodLength

    def canvas_uri_for(manifest_uri)
      # TODO: get the 'manifest' path element out of these URIs
      UCBLIT::Util::URIs.append(manifest_uri, "canvas/p#{number}")
    end

    def annotation_id_for(manifest_uri)
      # TODO: get the 'manifest' path element out of these URIs
      UCBLIT::Util::URIs.append(manifest_uri, "annotation/p#{number}-image")
    end

    def tiff_uri_for(image_dir_uri)
      UCBLIT::Util::URIs.append(image_dir_uri, basename)
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
  # rubocop:enable Metrics/ClassLength
end
