# ------------------------------------------------------------
# Make classes in app/lib available
require 'zeitwerk'

module UCBEARS
  # TODO: Share code with config/initializers/inflections.rb?
  class CollectorInflector < Zeitwerk::Inflector
    ACRONYMS = %w[IIIF UCBLIT UCBEARS].freeze

    def camelize(basename, _abspath)
      overrides[basename] || basename.split('_').map { |s| capitalize(s) }.join
    end

    def capitalize(s)
      s.upcase.tap { |s_upcased| return s_upcased if ACRONYMS.include?(s_upcased) }
      s.capitalize
    end
  end
end

Zeitwerk::Loader.new.tap do |loader|
  loader.inflector = UCBEARS::CollectorInflector.new
  lib_path = File.expand_path('../../app/lib', __dir__)
  loader.push_dir(lib_path)
  loader.setup
end
