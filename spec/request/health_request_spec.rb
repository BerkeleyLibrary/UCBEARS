require 'rails_helper'
require 'support/iiif_check_helper'

RSpec.describe 'Health Checks', type: :request do
  describe 'GET /health' do
    let(:health_path) { '/health' }

    context 'when all systems are functional' do
      before do
        iiif_server = OkComputer::Registry.fetch('iiif-server')
        iiif_item = OkComputer::Registry.fetch('iiif-item')
        test_item = OkComputer::Registry.fetch('test-item-exists')

        allow(iiif_item).to receive(:run) do
          iiif_item.instance_variable_set(:@success, true)
          iiif_item.instance_variable_set(:@message, 'OK')
          iiif_item
        end

        allow(iiif_server).to receive(:run) do
          iiif_server.instance_variable_set(:@success, true)
          iiif_server.instance_variable_set(:@message, 'OK')
          iiif_server
        end

        allow(test_item).to receive(:run) do
          test_item.instance_variable_set(:@success, true)
          test_item.instance_variable_set(:@message, 'OK')
          test_item
        end
      end

      it 'returns 200 OK and success in JSON' do
        get health_path
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json.dig('database', 'success')).to be true
        expect(json.dig('iiif-server', 'success')).to be true
        expect(json.dig('iiif-item', 'success')).to be true
        expect(json.dig('test-item-exists', 'success')).to be true
      end
    end

    context 'when a critical service is down' do

      before do
        # Apparently OkComputer wraps 'check' inside 'run'.
        # By stubbing 'run' on any ActiveRecordCheck, we take total control.
        allow_any_instance_of(OkComputer::ActiveRecordCheck).to receive(:run) do |instance|
          # Manually set the internal state of the check to 'failed'
          instance.instance_variable_set(:@failure_occurred, true)
          instance.instance_variable_set(:@message, 'DB Connection Error')
          instance
        end

        # Ensure the collection sees a failure:
        allow_any_instance_of(OkComputer::CheckCollection)
          .to receive(:success?)
          .and_return(false)

        test_uri = 'http://example.test/health'
        allow_any_instance_of(HealthChecks::IIIFServerCheck)
          .to receive(:iiif_test_uri).and_return(test_uri)

        stub_request(:get, test_uri)
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'User-Agent' => 'Faraday v2.7.5'
            }
          ).to_return(status: 200, body: '')
      end

      it 'returns a 500 Internal Server Error' do
        get health_path
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'reports the failure in the JSON body' do
        get health_path
        json = JSON.parse(response.body)

        expect(json.dig('database', 'success')).to be false
        expect(json.dig('database', 'message')).to eq('DB Connection Error')
      end
    end
  end
end
