require 'rails_helper'

context HealthController, type: :request do
  let(:iiif_url) { 'http://iipsrv.test/iiif/' }
  let(:config_instance_vars) { %i[@iiif_base_uri @lending_root_path] }

  RSpec::Matchers.define :be_a_health_result do
    match do |response|
      json_result = JSON.parse(response.body)
      %w[status details].each { |k| json_result.key?(k) }
    rescue JSON::ParserError
      false
    end

    failure_message do |response|
      "expected a JSON health result, got #{response.body}"
    end
  end

  RSpec::Matchers.define :be_passing do
    expected_status = Health::Status::PASS

    match do |response|
      next false unless response.status == expected_status.http_status
      next false unless (json_result = parse_result(response))

      json_result['status'] == expected_status.as_json
    end

    failure_message do |response|
      if (json_result = parse_result(response)) && (details = json_result['details'])
        failed_checks = details.filter_map do |check, result|
          next check unless result['status'] == expected_status.as_json
        end

        return "expected #{expected_status}, got #{response.status}; failed checks: #{failed_checks.join(', ')}; body: #{response.body}"
      end

      "expected #{expected_status}, got #{response.status}; body: #{response.body}"
    end
  end

  # TODO: Implement 529 fail
  RSpec::Matchers.define :be_warning do
    expected_status = Health::Status::WARN

    match do |response|
      next false unless response.status == expected_status.http_status
      next false unless (json_result = parse_result(response))

      json_result['status'] == expected_status.as_json
    end

    failure_message do |response|
      "expected #{expected_status}, got #{response.status}; body: #{response.body}"
    end
  end

  RSpec::Matchers.define :have_states do |expected_states_by_check|
    match do |response|
      next false unless (json_result = parse_result(response))
      next false unless (details = json_result['details'])

      expected_states_by_check.all? do |check, expected_state|
        actual_state = (check_result = details[check.to_s]) && check_result['status']
        actual_state == expected_state.as_json
      end
    end

    failure_message do |response|
      expected_states_msg = expected_states_by_check
        .map { |check, expected_state| "#{check}: #{expected_state.as_json}" }.join(', ')

      if (json_result = parse_result(response)) && (details = json_result['details'])
        mismatched_check_msg = details.each_with_object([]) do |(check, result), msg_segments|
          expected_state = expected_states_by_check[check.to_sym]
          actual_state = result['status']
          msg_segments << [check, actual_state].join(': ') if actual_state != expected_state.as_json
        end.join(', ')

        return "expected #{expected_states_msg}, got #{mismatched_check_msg}; body: #{response.body}"
      end

      "expected #{expected_states_msg}; got #{response.body}"
    end
  end

  def parse_result(response)
    json_result = JSON.parse(response.body)
    return unless json_result.is_a?(Hash)

    json_result.with_indifferent_access
  rescue JSON::ParserError
    nil
  end

  def stub_iiif_success!
    stub_request(:head, /#{iiif_url}/).to_return(
      status: 200,
      headers: {
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Headers' => 'X-Requested-With'
      }
    )
  end

  def all_passing
    Health::Check::VALIDATION_METHODS.each_with_object({}) do |check, states|
      states[check] = Health::Status::PASS
    end
  end

  def passing_except(*warn)
    {}.tap do |states|
      warn_checks = Array(warn)
      warn_checks.each { |check| states[check] = Health::Status::WARN }
      Health::Check::VALIDATION_METHODS.each do |check|
        next if warn_checks.include?(check)

        states[check] = Health::Status::PASS
      end
    end
  end

  before(:each) do
    @env_orig = Lending::Config::ENV_VARS.each_with_object({}) do |var, env|
      env[var] = ENV[var]
    end

    @config_ivars_orig = config_instance_vars.each_with_object({}) do |var, ivals|
      ivals[var] = Lending::Config.instance_variable_get(var)
    end
  end

  after(:each) do
    @env_orig.each { |var, val| ENV[var] = val }
    @config_ivars_orig.each { |var, val| Lending::Config.instance_variable_set(var, val) }
  end

  describe :health do
    before(:each) do
      Lending::Config.instance_variable_set(:@iiif_base_uri, URI.parse('http://iipsrv.test/iiif/'))
      Lending::Config.instance_variable_set(:@lending_root_path, Pathname.new('spec/data/lending'))
    end

    describe 'success' do
      before(:each) do

        stub_iiif_success!
        create(:complete_item)
      end

      it 'returns a PASS response' do
        get health_path

        expect(response).to be_a_health_result
        expect(response).to be_passing

        expect(response).to have_states(all_passing)
      end
    end

    describe 'pending migrations' do
      before(:each) do
        stub_iiif_success!
        create(:complete_item)

        allow(ActiveRecord::Migration).to receive(:check_pending!).and_raise(ActiveRecord::PendingMigrationError)
      end

      it 'returns a WARN response' do
        get health_path

        expect(response).to be_a_health_result
        expect(response).to be_warning
        expect(response).to have_states(passing_except(:no_pending_migrations))
      end
    end

    context 'IIIF server not reachable' do
      before(:each) do
        stub_request(:any, /#{iiif_url}/).to_raise(Errno::ECONNREFUSED)

        create(:complete_item)
      end

      it 'returns a WARN response' do
        get health_path

        expect(response).to be_a_health_result
        expect(response).to be_warning
        expect(response).to have_states(passing_except(:iiif_server_reachable))
        expect(response.body).to match(/Connection refused/)
      end
    end

    context 'IIIF test image not found' do
      let(:expected_status) { 404 }

      before(:each) do
        stub_request(:any, /#{iiif_url}/).to_return(status: expected_status)

        create(:complete_item)
      end

      it 'returns a WARN response' do
        get health_path

        expect(response).to be_a_health_result
        expect(response).to be_warning
        expect(response).to have_states(passing_except(:iiif_server_reachable))
        expect(response.body).to include(expected_status.to_s)
      end
    end

    context 'IIIF server bad hostname' do
      let(:expected_msg) { 'Failed to open TCP connection to test.test:80 (getaddrinfo: nodename nor servname provided, or not known)' }

      before(:each) do
        stub_request(:any, /#{iiif_url}/).to_raise(SocketError.new(expected_msg))

        create(:complete_item)
      end

      it 'returns a WARN response' do
        get health_path

        expect(response).to be_a_health_result
        expect(response).to be_warning
        expect(response).to have_states(passing_except(:iiif_server_reachable))
        expect(response.body).to include(expected_msg)
      end
    end

    context 'IIIF base URL not configured' do
      before(:each) do
        ENV[Lending::Config::ENV_IIIF_BASE] = nil
        allow(Rails.application.config).to receive(Lending::Config::CONFIG_KEY_IIIF_BASE).and_return(nil)
        Lending::Config.instance_variable_set(:@iiif_base_uri, nil)

        stub_iiif_success!
        create(:complete_item)
      end

      it 'returns a WARN response' do
        get health_path

        expect(response).to be_a_health_result
        expect(response).to be_warning
        expect(response).to have_states(passing_except(:iiif_server_reachable))
      end
    end

    context 'Invalid IIIF base URL' do
      before(:each) do
        ENV[Lending::Config::ENV_IIIF_BASE] = 'I am not a URI'
        Lending::Config.instance_variable_set(:@iiif_base_uri, nil)

        stub_iiif_success!
        create(:complete_item)
      end

      it 'returns a WARN response' do
        get health_path

        expect(response).to be_a_health_result
        expect(response).to be_warning
        expect(response).to have_states(passing_except(:iiif_server_reachable))
      end
    end

    context 'no test item' do
      it 'returns a WARN response' do
        get health_path

        expect(response).to be_a_health_result
        expect(response).to be_warning
        expect(response).to have_states(passing_except(:iiif_server_reachable, :test_item_exists))
      end
    end

    context 'Lending root not readable' do
      before(:each) do
        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |dir|
          Lending::Config.instance_variable_set(:@lending_root_path, Pathname.new(dir))
        end
        expect(Lending::Config.lending_root_path.directory?).to eq(false) # just to be sure

        stub_iiif_success!
      end

      it 'returns a WARN response' do
        get health_path

        expect(response).to be_a_health_result
        expect(response).to be_warning
        expect(response).to have_states(passing_except(:lending_root_path, :test_item_exists, :iiif_server_reachable))
      end
    end

    context 'Lending root not configured' do
      before(:each) do
        ENV[Lending::Config::ENV_ROOT] = nil
        allow(Rails.application.config).to receive(Lending::Config::CONFIG_KEY_ROOT).and_return(nil)
        Lending::Config.instance_variable_set(:@lending_root_path, nil)

        stub_iiif_success!
      end

      it 'returns a WARN response' do
        get health_path

        expect(response).to be_a_health_result
        expect(response).to be_warning
        expect(response).to have_states(passing_except(:lending_root_path, :test_item_exists, :iiif_server_reachable))
      end
    end

    context 'Invalid lending root' do
      before(:each) do
        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |dir|
          ENV[Lending::Config::ENV_ROOT] = dir
        end
        expect(File.directory?(ENV[Lending::Config::ENV_ROOT])).to eq(false) # just to be sure
        Lending::Config.instance_variable_set(:@lending_root_path, nil)

        stub_iiif_success!
      end

      it 'returns a WARN response' do
        get health_path

        expect(response).to be_a_health_result
        expect(response).to be_warning
        expect(response).to have_states(passing_except(:lending_root_path, :test_item_exists, :iiif_server_reachable))
      end
    end
  end
end
