require 'pathname'
require 'uri'

module Lending
  module Config
    ENV_IIIF_BASE = 'LIT_IIIF_BASE_URL'.freeze
    ENV_ROOT = 'LIT_LENDING_ROOT'.freeze

    ENV_VARS = [ENV_IIIF_BASE, ENV_ROOT].freeze

    CONFIG_KEY_IIIF_BASE = :iiif_base_url
    CONFIG_KEY_ROOT = :lending_root

    RAILS_CONFIG_IIIF_BASE = "Rails.application.config.#{CONFIG_KEY_IIIF_BASE}".freeze
    RAILS_CONFIG_ROOT = "Rails.application.config.#{CONFIG_KEY_ROOT}".freeze

    class << self

      def iiif_base_uri
        @iiif_base_uri ||= default_iiif_base
      end

      def lending_root_path
        @lending_root_path ||= default_lending_root
      end

      private

      def reset!
        @iiif_base_uri = nil
        @lending_root_path = nil
      end

      def default_iiif_base
        (env_iiif_base || rails_iiif_base).tap do |iiif_base|
          raise(ConfigException, "IIIF base URL not set in #{ENV_IIIF_BASE} or #{RAILS_CONFIG_IIIF_BASE}") unless iiif_base
        end
      end

      def default_lending_root
        (env_lending_root || rails_lending_root).tap do |lending_root|
          raise(ConfigException, "Lending root not set in #{ENV_ROOT} or #{RAILS_CONFIG_ROOT}") unless lending_root
        end
      end

      def env_iiif_base
        iiif_base_uri_from(ENV[ENV_IIIF_BASE])
      end

      def rails_iiif_base
        iiif_base_uri_from(rails_config_value(CONFIG_KEY_IIIF_BASE))
      end

      def env_lending_root
        env_root = ENV[ENV_ROOT]
        lending_root_path_from(env_root)
      end

      def rails_lending_root
        rails_root = rails_config_value(CONFIG_KEY_ROOT)
        lending_root_path_from(rails_root)
      end

      def iiif_base_uri_from(iiif_base_url)
        return unless iiif_base_url

        URI.parse(iiif_base_url.to_s)
      rescue URI::InvalidURIError => e
        raise ConfigException, "Invalid IIIF base URI: #{e}"
      end

      def lending_root_path_from(lending_root_dirname)
        return unless lending_root_dirname

        unless File.directory?(lending_root_dirname)
          raise ConfigException,
                "Invalid lending root: #{lending_root.inspect} is not a directory"
        end

        Pathname.new(lending_root_dirname)
      end

      def rails_config_value(key)
        return unless (rails_config = self.rails_config)
        return unless rails_config.respond_to?(key)

        rails_config.send(key)
      end

      def rails_config
        return unless defined?(Rails)
        return unless (app = Rails.application)

        app.config
      end
    end
  end
end
