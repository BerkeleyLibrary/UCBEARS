require 'rails_helper'

module Lending
  describe Config do
    let(:config_instance_vars) { %i[@iiif_base_uri @lending_root_path] }

    attr_reader :env_values_orig
    attr_reader :attr_values_orig

    before(:each) do
      @env_values_orig = [Config::ENV_IIIF_BASE, Config::ENV_ROOT].to_h { |var| [var, ENV[var]] }
      @attr_values_orig = config_instance_vars.to_h { |var| [var, Config.instance_variable_get(var)] }
    end

    after(:each) do
      env_values_orig.each { |var, val| ENV[var] = val }
      attr_values_orig.each { |var, val| Config.instance_variable_set(var, val) }
    end

    describe :iiif_base_uri do
      before(:each) do
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
      before(:each) do
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
  end
end
