require 'erb'
require 'iiif/presentation'
require 'berkeley_library/util/uris'

module Lending
  class IIIFManifest
    include BerkeleyLibrary::Logging

    MANIFEST_NAME = 'manifest.json'.freeze
    MANIFEST_TEMPLATE_NAME = "#{MANIFEST_NAME}.erb".freeze

    MF_TAG = '<%= manifest_uri %>'.freeze
    IMG_TAG = '<%= image_dir_uri %>'.freeze

    MF_URL_PLACEHOLDER = 'https://ucbears.invalid/manifest'.freeze
    IMGDIR_URL_PLACEHOLDER = 'https://ucbears.invalid/imgdir'.freeze

    attr_reader :title
    attr_reader :author
    attr_reader :dir_path
    attr_reader :record_id
    attr_reader :barcode

    def initialize(title:, author:, dir_path:)
      @title = title
      @author = author
      @dir_path = PathUtils.ensure_dirpath(dir_path)
      @record_id, @barcode = PathUtils.decompose_dirname(@dir_path)
    end

    def pages
      @pages ||= Page.all_from_directory(dir_path)
    end

    def dir_basename
      dir_path.basename.to_s
    end

    # rubocop:disable Naming/PredicateName
    def has_manifest?
      manifest_path.file? || erb_path.file?
    end
    # rubocop:enable Naming/PredicateName

    # rubocop:disable Metrics/AbcSize
    def to_json_manifest(manifest_uri, image_root_uri)
      image_dir_uri = BerkeleyLibrary::Util::URIs.append(image_root_uri, ERB::Util.url_encode(dir_basename))

      raise ArgumentError, "#{record_id}_#{barcode}: manifest not found in #{dir_path}" unless manifest_path.file? || erb_path.file?

      if manifest_path.file?
        manifest_path.read.tap do |json|
          json.gsub!(MF_URL_PLACEHOLDER, manifest_uri.to_s)
          json.gsub!(IMGDIR_URL_PLACEHOLDER, image_dir_uri.to_s)
        end
      elsif erb_path.file?
        # depends on: manifest_uri, image_dir_uri
        template.result(binding)
      end
    end
    # rubocop:enable Metrics/AbcSize

    def write_manifest!
      logger.info("#{self}: Writing #{manifest_path}")
      manifest_json.tap { |json| manifest_path.open('w') { |f| f.write(json) } }
    end

    def erb_path
      @erb_path ||= dir_path.join(MANIFEST_TEMPLATE_NAME)
    end

    def manifest_path
      @manifest_path ||= dir_path.join(MANIFEST_NAME)
    end

    def to_s
      @s ||= "#{self.class.name.split('::').last}@#{object_id}"
    end

    private

    def manifest_json
      create_manifest(MF_URL_PLACEHOLDER, IMGDIR_URL_PLACEHOLDER)
        .to_json(pretty: true)
    end

    def template
      @template ||= ERB.new(erb_source)
    end

    def erb_source
      @erb_source ||= erb_path.file? ? erb_path.read : write_manifest_erb!
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

  end
end
