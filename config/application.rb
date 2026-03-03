require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_view/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Read .env file, but only in local (non-Docker) development
require 'dotenv/load' if Rails.env.development? &&
  !BerkeleyLibrary::Docker.running_in_container?

module UCBEARS
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Set time zone
    config.time_zone = 'America/Los_Angeles'

    # TODO: fail fast if ENV not configured?
    BerkeleyLibrary::Alma::Config.default!

    config.x.cas_host = ENV.fetch('CAS_HOST') do
      Rails.env.production? ? 'auth.berkeley.edu' : 'auth-test.berkeley.edu'
    end

    config.after_initialize do
      BuildInfo.log!
    end
  end
end
