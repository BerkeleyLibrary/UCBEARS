require 'rails_helper'

context HealthController, type: :request do
  let(:iiif_url) { 'http://ucbears-iiif/iiif/' }

  let(:config_instance_vars) { %i[@iiif_base_uri @lending_root_path] }
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

  RSpec.shared_examples 'a failed check' do |failed_check, cascade_failures = []|
    it 'returns a warning status' do
      get send(path_helper)
      expect(response.status).to eq(Health::Status::WARN.http_status)

      result = JSON.parse(response.body)
      expect(result['status']).to eq('warn')
      details = result['details']

      failed_check_details = details[failed_check]
      expect(failed_check_details).not_to be_nil
      expect(failed_check_details['status']).to eq('warn')

      aggregate_failures 'other checks' do
        Health::Check::VALIDATION_METHODS.each do |m|
          next if (check = m.to_s) == failed_check

          check_details = details[check]
          expect(check_details).not_to be_nil

          expected_status = cascade_failures.include?(check.to_s) ? 'warn' : 'pass'
          expect(check_details['status']).to eq(expected_status), "Wrong status returned for #{check}: #{check_details}"
        end
      end
    end
  end

  RSpec.shared_examples 'a health check' do |path_helper|
    let(:path_helper) { path_helper }

    context 'success' do
      before(:each) do
        Lending::Config.instance_variable_set(:@iiif_base_uri, URI.parse('http://ucbears-iiif/iiif/'))
        Lending::Config.instance_variable_set(:@lending_root_path, Pathname.new('spec/data/lending'))

        stub_request(:head, /#{iiif_url}/).to_return(status: 200)
        create(:complete_item)
      end

      it 'returns a successful status' do
        get send(path_helper)

        body_expected = {
          'status' => 'pass',
          'details' => Health::Check::VALIDATION_METHODS.each_with_object({}) { |m, d| d[m.to_s] = { 'status' => 'pass' } }
        }
        body_actual = JSON.parse(response.body)
        expect(body_actual).to eq(body_expected)

        expect(response).to be_successful
      end
    end

    context 'failure' do
      context 'with reachable IIIF server' do
        before(:each) do
          stub_request(:head, /#{iiif_url}/).to_return(status: 200)
        end

        context 'with complete items' do
          before(:each) do
            create(:complete_item)
          end

          describe :iiif_base_uri do
            before(:each) do
              Lending::Config.instance_variable_set(:@iiif_base_uri, nil)
              ENV[Lending::Config::ENV_IIIF_BASE] = nil

              Lending::Config.instance_variable_set(:@lending_root_path, Pathname.new('spec/data/lending'))
            end

            it_behaves_like('a failed check', 'iiif_base_uri', %w[iiif_test_uri iiif_server_reachable])
          end

          describe :lending_root_path do
            before(:each) do
              Lending::Config.instance_variable_set(:@lending_root_path, nil)
              ENV[Lending::Config::ENV_ROOT] = nil

              Lending::Config.instance_variable_set(:@iiif_base_uri, URI.parse('http://ucbears-iiif/iiif/'))
            end

            it_behaves_like('a failed check', 'lending_root_path', %w[iiif_server_reachable])
          end
        end
      end

      describe :iiif_server_reachable do
        let(:failed_check) { 'iiif_server_reachable' }

        before(:each) do
          Lending::Config.instance_variable_set(:@iiif_base_uri, URI.parse('http://ucbears-iiif/iiif/'))
          Lending::Config.instance_variable_set(:@lending_root_path, Pathname.new('spec/data/lending'))
        end

        context 'with complete items' do
          before(:each) do
            create(:complete_item)
          end

          context 'timeout' do
            before(:each) do
              stub_request(:any, /#{iiif_url}/).to_timeout
            end

            it_behaves_like('a failed check', 'iiif_server_reachable')
          end

          context 'connection refused' do
            before(:each) do
              stub_request(:any, /#{iiif_url}/).to_raise(Errno::ECONNREFUSED)
            end

            it_behaves_like('a failed check', 'iiif_server_reachable')
          end

          context '404' do
            before(:each) do
              stub_request(:any, /#{iiif_url}/).to_return(status: 404)
            end

            it_behaves_like('a failed check', 'iiif_server_reachable')
          end
        end

        context 'with no complete items' do
          before(:each) do
            expect(LendingItem.exists?).to eq(false) # just to be sure
          end

          it_behaves_like('a failed check', 'iiif_server_reachable')
        end

        context 'with an exception in item lookup' do
          before(:each) do
            allow(LendingItem).to receive(:active).and_raise(ActiveRecord::RecordNotFound)
          end

          it_behaves_like('a failed check', 'iiif_server_reachable')
        end

      end
    end
  end

  describe :health do
    it_behaves_like('a health check', :health_path)
  end
end
