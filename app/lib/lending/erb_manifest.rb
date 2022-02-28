require 'erb'

module Lending
  module ErbManifest
    include ManifestConstants

    MANIFEST_TEMPLATE_NAME = "#{MANIFEST_NAME}.erb".freeze

    # noinspection RubyUnusedLocalVariable
    def render_erb_template(manifest_uri, image_dir_uri)
      # depends on: manifest_uri, image_dir_uri
      erb_template.result(binding)
    end

    def erb_path
      @erb_path ||= dir_path.join(MANIFEST_TEMPLATE_NAME)
    end

    def erb_template
      @erb_template ||= ERB.new(erb_source)
    end

    def erb_source
      @erb_source ||= erb_path.read
    end

    def erb_template?
      erb_path.exist?
    end
  end
end
