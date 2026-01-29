require 'rails_helper'

module Lending
  describe Config do
    let(:config_instance_vars) { %i[@iiif_base_uri @lending_root_path] }

    attr_reader :env_values_orig
    attr_reader :attr_values_orig

    before do
      @env_values_orig = [Config::ENV_IIIF_BASE, Config::ENV_ROOT].to_h { |var| [var, ENV[var]] }
      @attr_values_orig = config_instance_vars.to_h { |var| [var, Config.instance_variable_get(var)] }
    end

    after do
      env_values_orig.each { |var, val| ENV[var] = val }
      attr_values_orig.each { |var, val| Config.instance_variable_set(var, val) }
    end

    describe :iiif_base_uri do
      before do
        Config.instance_variable_set(:@iiif_base_uri, nil)
      end

      it 'reads from ENV' do
        Config.instance_variable_set(:@iiif_base_uri, nil)
        expected_url = 'http://example.org/iiif'
        ENV[Config::ENV_IIIF_BASE] = expected_url
        expect(Config.iiif_base_uri).to eq(URI.parse(expected_url))
      end

      it "reads from #{Lending::Config::RAILS_CONFIG_IIIF_BASE}" do
        expected_value_str = Rails.application.config.iiif_base_url
        expected_value = URI.parse(expected_value_str)
        expect(Config.iiif_base_uri).to eq(expected_value)
      end
    end

    describe :lending_root_path do
      before do
        Config.instance_variable_set(:@lending_root_path, nil)
      end

      it 'reads from ENV' do
        Config.instance_variable_set(:@lending_root_path, nil)
        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |dir|
          ENV[Config::ENV_ROOT] = dir
          expect(Config.lending_root_path).to eq(Pathname.new(dir))
        end
      end

      it "reads from #{Lending::Config::RAILS_CONFIG_ROOT}" do
        expected_value_str = Rails.application.config.lending_root
        expected_value = Pathname.new(expected_value_str)
        expect(Config.lending_root_path).to eq(expected_value)
      end
    end

    describe 'error handling and rails config fallbacks' do
      before do
        Config.instance_variable_set(:@iiif_base_uri, nil)
        Config.instance_variable_set(:@lending_root_path, nil)
      end

      it 'raises ConfigException when ENV IIIF base URL is invalid' do
        ENV[Config::ENV_IIIF_BASE] = 'http://exa mple.org/bad uri'

        expect { Config.iiif_base_uri }.to raise_error(Lending::ConfigException, /Invalid IIIF base URI:/)
      end

      it 'raises ConfigException when ENV lending root is not a directory' do
        ENV[Config::ENV_ROOT] = '/definitely/not/a/real/path'

        expect { Config.lending_root_path }.to raise_error(Lending::ConfigException, /Invalid lending root:/)
      end

      it 'reads IIIF base from Rails config when ENV is unset' do
        ENV[Config::ENV_IIIF_BASE] = nil
        Config.instance_variable_set(:@iiif_base_uri, nil)

        expected = URI.parse(Rails.application.config.iiif_base_url.to_s)
        expect(Config.iiif_base_uri).to eq(expected)
      end

      it 'reads lending root from Rails config when ENV is unset' do
        ENV[Config::ENV_ROOT] = nil
        Config.instance_variable_set(:@lending_root_path, nil)

        expected = Pathname.new(Rails.application.config.lending_root.to_s)
        expect(Config.lending_root_path).to eq(expected)
      end

      it 'returns nil from rails_config_value when Rails is not defined' do
        ENV[Config::ENV_IIIF_BASE] = nil
        Config.instance_variable_set(:@iiif_base_uri, nil)

        # Temporarily hide Rails constant so `defined?(Rails)` is false
        rails_const = Object.const_get(:Rails)
        Object.send(:remove_const, :Rails)
        begin
          expect { Config.iiif_base_uri }.to raise_error(Lending::ConfigException, /IIIF base URL not set/)
        ensure
          Object.const_set(:Rails, rails_const)
        end
      end

      it 'returns nil from rails_config when Rails.application is nil' do
        ENV[Config::ENV_IIIF_BASE] = nil
        Config.instance_variable_set(:@iiif_base_uri, nil)

        allow(Rails).to receive(:application).and_return(nil)

        expect { Config.iiif_base_uri }.to raise_error(Lending::ConfigException, /IIIF base URL not set/)
      end
    end
  end
end
