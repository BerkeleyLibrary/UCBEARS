ActiveSupport::Inflector.inflections do |inflect|
  %w[IIIF UCBLIT UCBEARS].each { |a| inflect.acronym(a) }
end
