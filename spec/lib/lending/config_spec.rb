require 'rails_helper'

module Lending
  describe Config do
    attr_reader :env_values_orig
    attr_reader :attr_values_orig

    before(:each) do
      @env_values_orig = [Config::ENV_IIIF_BASE, Config::ENV_ROOT].map { |var| [var, ENV[var]] }.to_h
      @attr_values_orig = %i[@iiif_base_uri @lending_root_path].map { |var| [var, Config.instance_variable_get(var)] }.to_h
    end

    after(:each) do
      env_values_orig.each { |var, val| ENV[var] = val }
      attr_values_orig.each { |var, val| Config.instance_variable_set(var, val) }
    end

    describe :iiif_base_uri do
      it 'reads from ENV' do
        Config.instance_variable_set(:@iiif_base_uri, nil)
        expected_url = 'http://example.org/iiif'
        ENV[Config::ENV_IIIF_BASE] = expected_url
        expect(Config.iiif_base_uri).to eq(URI.parse(expected_url))
      end
    end

    describe :lending_root_path do
      it 'reads from ENV' do
        Config.instance_variable_set(:@lending_root_path, nil)
        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |dir|
          ENV[Config::ENV_ROOT] = dir
          expect(Config.lending_root_path).to eq(Pathname.new(dir))
        end
      end
    end

  end
end
