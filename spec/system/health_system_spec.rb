require 'capybara_helper'

describe HealthController, type: :system do
  let(:config_instance_vars) { %i[@iiif_base_uri @lending_root_path] }

  before(:each) do
    @config_ivars_orig = config_instance_vars.each_with_object({}) do |var, ivals|
      ivals[var] = Lending::Config.instance_variable_get(var)
    end

    @webmock_config = %i[allow_localhost allow net_http_connect_on_start].each_with_object({}) do |attr, opts|
      opts[attr] = WebMock::Config.instance.send(attr)
    end
    webmock_tmp_config = @webmock_config.dup.tap do |conf|
      conf[:allow] = (conf[:allow] || []) + ['iipsrv.test']
    end
    WebMock.disable_net_connect!(webmock_tmp_config)

    Lending::Config.instance_variable_set(:@iiif_base_uri, URI.parse('http://iipsrv.test/iiif/'))
    Lending::Config.instance_variable_set(:@lending_root_path, Pathname.new('spec/data/lending'))

    create(:complete_item)
  end

  after(:each) do
    @config_ivars_orig.each { |var, val| Lending::Config.instance_variable_set(var, val) }

    WebMock.disable_net_connect!(@webmock_config)
  end

  describe :health do
    it 'returns a successful health check' do
      visit health_path

      body_expected = {
        'status' => 'pass',
        'details' => Health::Check::VALIDATION_METHODS.each_with_object({}) { |m, d| d[m.to_s] = { 'status' => 'pass' } }
      }

      body_actual = JSON.parse(page.text)
      expect(body_actual).to eq(body_expected)
    end
  end
end
