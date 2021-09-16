require 'pathname'
require 'uri'

module Lending
  module Config
    ENV_IIIF_BASE = 'LIT_IIIF_BASE_URL'.freeze
    ENV_ROOT = 'LIT_LENDING_ROOT'.freeze

    ENV_VARS = [ENV_IIIF_BASE, ENV_ROOT].freeze

    class << self
      def iiif_base_uri
        @iiif_base_uri ||= URI.parse(env_iiif_base)
      end

      def lending_root_path
        @lending_root_path ||= Pathname.new(env_lending_root)
      end

      private

      def env_iiif_base
        ENV[ENV_IIIF_BASE].tap do |iiif_base|
          raise ConfigException, "#{ENV_ROOT} not set" unless iiif_base
        end
      end

      def env_lending_root
        ENV[ENV_ROOT].tap do |lending_root|
          raise ConfigException, "#{ENV_ROOT} not set" unless lending_root
          raise ConfigException, "#{ENV_ROOT} #{lending_root.inspect} is not a directory" unless File.directory?(lending_root)
        end
      end
    end
  end
end
