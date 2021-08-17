module Lending
  ENV_ROOT = 'LIT_LENDING_ROOT'.freeze
end

Dir.glob(File.expand_path('lending/*.rb', __dir__)).sort.each(&method(:require))
