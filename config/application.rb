# ------------------------------------------------------------
# Read Docker secrets into the environment.

require_relative '../lib/docker'
Docker::Secret.setup_environment!

# ------------------------------------------------------------
# Standard Rails initialization

require File.expand_path('boot', __dir__)

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Framework
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Set time zone
    config.time_zone = 'America/Los_Angeles'

    # TODO: fail fast if ENV not configured?
  end
end
