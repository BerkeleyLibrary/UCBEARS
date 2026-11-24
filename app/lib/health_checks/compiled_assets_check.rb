module HealthChecks
  class CompiledAssetsCheck < OkComputer::Check
    ASSETS = %w[application.js items.js terms.js application.css].freeze

    def check
      manifest = Rails.application.assets_manifest
      missing = ASSETS.reject do |name|
        compiled = manifest.assets[name]
        compiled && File.file?(File.join(manifest.directory, compiled))
      end

      if missing.empty?
        mark_message 'Required assets are compiled'
      else
        mark_failure
        mark_message "Missing compiled assets: #{missing.join(', ')}"
      end
    end
  end
end
