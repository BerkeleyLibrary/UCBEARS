require_relative '../lib/docker'

# Read Docker secrets into the environment. Must be before 'rails/all'.
Docker::Secret.setup_environment!

require_relative 'boot'
require 'rails/all'

# Read .env in local dev and test, but not in Docker
require 'dotenv/load' unless Rails.env.production? || Docker.running_in_container?

Bundler.require(*Rails.groups)

module Framework
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    config.time_zone = 'America/Los_Angeles'

    # Load our custom config. This is implicitly consumed in a few remaining
    # places (e.g. RequestMailer). A good development improvement would be to
    # inject those configs like we do with the Patron class.
    config.altmedia = config_for(:altmedia)

    # TODO: Switch to a persistent backend store like delayed_job
    #       (but make sure to update async logging tests in jobs_helper.rb)
    config.active_job.queue_adapter = :async

    # @note By default, Rails wraps fields that contain a validation error with
    #   a div classed "field_with_errors". This messes up Bootstrap's styling
    #   for feedback messages, so I've disabled the Rails' default.
    config.action_view.field_error_proc = proc { |tag, _instance| tag }

    # Alma API for handling Fees/Fines:
    config.alma_api_url = config.altmedia['alma_api_url']
    config.alma_api_key = config.altmedia['alma_api_key']

    # Setup paypal payflow link:
    config.paypal_payflow_url = config.altmedia['paypal_payflow_url']
    config.paypal_payflow_login = config.altmedia['paypal_payflow_login']

    # Setup ucblit-tind for TIND Downloader:
    config.tind_base_uri = config.altmedia['tind_base_uri']
    config.tind_api_key = config.altmedia['tind_api_key']

    # Lending
    config.image_server_base_uri = config.altmedia['image_server_base_uri']

    # TODO: simplify this once stacks all have LENDING_ROOT
    config.iiif_final_dir = if (lending_root = config.altmedia['lending_root_dir']).blank?
                              config.altmedia['iiif_final_dir']
                            else
                              File.join(lending_root, 'final')
                            end
  end
end
