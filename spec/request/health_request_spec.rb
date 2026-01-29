require 'rails_helper'

RSpec.describe 'Health Checks', type: :request do
  describe 'GET /health' do
    let(:health_path) { '/health' }

    context 'when all systems are functional' do
      before do
        iiif = OkComputer::Registry.fetch('iiif-server')
        test_item = OkComputer::Registry.fetch('test-item-exists')

        allow(iiif).to receive(:run) do
          iiif.instance_variable_set(:@success, true)
          iiif.instance_variable_set(:@message, 'OK')
          iiif
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
