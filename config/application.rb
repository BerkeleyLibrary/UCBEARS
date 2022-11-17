# ------------------------------------------------------------
# Standard Rails initialization

require File.expand_path('boot', __dir__)

require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'

# TODO: figure out why Bundler.require() doesn't pick this up
require 'berkeley_library/logging/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Read .env file, but only in local (non-Docker) development
require 'dotenv/load' if Rails.env.development? &&
  !BerkeleyLibrary::Docker.running_in_container?

module UCBEARS
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Set time zone
    config.time_zone = 'America/Los_Angeles'

    # TODO: fail fast if ENV not configured?
    BerkeleyLibrary::Alma::Config.default!

    # CAS configuration
    # - NOTE: overridden in production.rb
    config.cas_host = ENV.fetch('CAS_HOST') { 'auth-test.berkeley.edu' }

    config.after_initialize do
      BuildInfo.log!
    end
  end
end
