require 'iiif/presentation'

module Lending
  module ManifestBuilder
    include ManifestConstants

    def write_manifest!
      logger.info("#{self}: Writing #{manifest_path}")
      mf = create_manifest(MF_URL_PLACEHOLDER, IMGDIR_URL_PLACEHOLDER)
      write_manifest(mf)
    end

    def write_manifest(mf)
      mf.to_json(pretty: true).tap { |json| manifest_path.open('w') { |f| f.write(json) } }
    end

    private

    def create_manifest(manifest_uri, image_dir_uri)
      logger.info("Creating new manifest for #{image_dir_uri}")

      IIIF::Presentation::Manifest.new.tap do |mf|
        mf['@id'] = manifest_uri
        mf.label = title
        add_metadata(mf, Title: title, Author: author)
        mf.sequences << create_sequence(manifest_uri, image_dir_uri)
      end
    end

    # TODO: share code between Page and IIIFItem
    def add_metadata(resource, **md)
      md.each { |k, v| resource.metadata << { label: k, value: v } }
    end

    def create_sequence(manifest_uri, image_dir_uri)
      IIIF::Presentation::Sequence.new.tap do |seq|
        pages.each do |page|
          seq.canvases << page.to_canvas(manifest_uri, image_dir_uri)
        end
      end
    end
  end
end
