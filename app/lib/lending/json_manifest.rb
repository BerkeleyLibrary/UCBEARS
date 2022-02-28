module Lending
  module JsonManifest
    include ManifestConstants

    def render_json_template(manifest_uri, image_dir_uri)
      manifest_path.read.tap do |json|
        json.gsub!(MF_URL_PLACEHOLDER, manifest_uri.to_s)
        json.gsub!(IMGDIR_URL_PLACEHOLDER, image_dir_uri.to_s)
      end
    end

    def manifest_path
      @manifest_path ||= dir_path.join(MANIFEST_NAME)
    end

    def json_template?
      manifest_path.exist?
    end
  end
end
