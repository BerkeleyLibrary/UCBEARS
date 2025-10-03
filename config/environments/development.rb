# Read .env in local dev, but not in Docker
require 'berkeley_library/docker'
require 'dotenv/load' unless BerkeleyLibrary::Docker.running_in_container?

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enabling Lograge
  config.lograge.enabled = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Use simple polling
  config.file_watcher = ActiveSupport::FileUpdateChecker

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  # config.assets.compile = false

  # A few tweaks to help with hotloading:
  config.assets.debug = true
  config.assets.check_precompiled_asset = false
  config.assets.compile = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  default_headers = config.action_dispatch.default_headers ||= {}
  default_headers['Access-Control-Allow-Origin'] = '*'
end
