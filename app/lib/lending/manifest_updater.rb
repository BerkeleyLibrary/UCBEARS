require 'iiif/presentation'

module Lending
  module ManifestUpdater
    include JsonManifest
    include ErbManifest
    include ManifestConstants

    CANVAS_ID_RE = %r{/canvas/p(?<num>[0-9]+)$}

    def update_manifest!
      return update_json_template! if json_template?
      return convert_erb_to_json! if erb_template?

      write_manifest!
    end

    private

    def update_json_template!
      json_src = manifest_path.read
      update_json(json_src)
    end

    def convert_erb_to_json!
      json_src = render_erb_template(MF_URL_PLACEHOLDER, IMGDIR_URL_PLACEHOLDER)
      update_json(json_src)
    rescue SyntaxError => e
      logger.warn(e)
      write_manifest!
    end

    def update_json(json_src)
      mf = IIIF::Service.parse(json_src)
      mf.label = title
      update_manifest(mf)
      write_manifest(mf)
    end

    def update_manifest(mf)
      ensure_metadata(mf, 'Title', title)
      ensure_metadata(mf, 'Author', author)
      mf.sequences.each do |seq|
        seq.canvases.each { |canvas| ensure_label(canvas) }
      end
    end

    def ensure_metadata(resource, label, value)
      if (title_entry = resource.metadata.find { |entry| entry['label'] == label })
        title_entry['value'] = value
      else
        add_metadata(resource, label => value)
      end
    end

    def ensure_label(canvas)
      raise ArgumentError, "Canvas number not found in ID: #{canvas['@id']}" unless (md = CANVAS_ID_RE.match(canvas['@id']))

      canvas.label = "#{Lending::Page::PAGE_CANVAS_LABEL} #{md[:num]}"
    end
  end
end
