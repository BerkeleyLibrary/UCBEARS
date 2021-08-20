require 'rspec-rails'

# Defines a separate task for each system test suite, because
#
# 1. system tests are slow, and you often want to run/debug
#    just one suite at a time
# 2. tests invoked via Rake may behave differently from tests
#    invoked via `bundle exec rspec`
# 3. RSpec::RakeTask doesn't make it easy to pass the name of
#    an individual test on the comand line
namespace :spec do
  namespace :system do
    suffix = '_system_spec.rb'
    Dir.glob("spec/system/*#{suffix}").each do |spec|
      basename = File.basename(spec)
      shortname = basename.sub(suffix, '')

      desc "Run specs in #{basename}"
      RSpec::Core::RakeTask.new(shortname => 'spec:prepare') do |t|
        t.pattern = spec
      end
    end
  end
end
