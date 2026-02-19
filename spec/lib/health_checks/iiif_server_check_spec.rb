require 'rails_helper'
require 'support/iiif_check_helper'

RSpec.describe HealthChecks::IIIFServerCheck do
  subject(:check) { described_class.new }

  def run_check
    check.run
    check
  end

  describe '#check' do
    it 'fails and sets message when the IIIF test uri cannot be constructed' do
      allow(Lending::Config).to receive(:iiif_base_uri).and_return(nil)

      run_check

      expect(check.message).to eq('Unable to construct healthcheck URI')

      if check.respond_to?(:failure?)
        expect(check.failure?).to be(true)
      else
        expect(check.instance_variable_get(:@failure_occurred)).to be(true)
      end
    end

    context 'with a valid IIIF base URI' do
      include_context 'with a valid IIIF base_uri'

      it 'fails and sets message when the GET request is not successful' do
        response = instance_double('Faraday::Response',
                                   success?: false,
                                   status: 503,
                                   headers: {})

        allow(connection).to receive(:get).with(test_uri).and_return(response)

        run_check

        expect(check.message).to match(/returned status 503/)

        if check.respond_to?(:failure?)
          expect(check.failure?).to be(true)
        else
          expect(check.instance_variable_get(:@failure_occurred)).to be(true)
        end
      end

      it 'fails and sets message when an exception is raised' do
        allow(connection).to receive(:get).with(test_uri).and_raise(StandardError, 'boom')

        run_check

        expect(check.message).to match('StandardError')

        if check.respond_to?(:failure?)
          expect(check.failure?).to be(true)
        else
          expect(check.instance_variable_get(:@failure_occurred)).to be(true)
        end
      end
    end
  end

  describe 'private helpers' do
    describe '#iiif_connection' do
      it 'configures Faraday timeouts' do
        conn = check.send(:iiif_connection)

        expect(conn.options.open_timeout).to eq(2)
        expect(conn.options.timeout).to eq(3)
      end
    end

    describe '#iiif_test_uri' do
      it 'returns nil when iiif_base_uri is nil' do
        allow(Lending::Config).to receive(:iiif_base_uri).and_return(nil)

        expect(check.send(:iiif_test_uri)).to be_nil
      end

      it 'builds a default test uri' do
        base_uri = URI('http://example.test/iiif/')
        allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)

        expect(URI).to receive(:join)
          .with(base_uri, '/health')
          .and_return('http://example.test/health')

        expect(check.send(:iiif_test_uri)).to eq('http://example.test/health')
      end
    end

    describe '#perform_request' do
      it 'returns a failure when it cannot construct test uri' do
        allow(Lending::Config).to receive(:iiif_base_uri).and_return(nil)

        result = check.send(:perform_request)

        expect(result).to eq(message: 'Unable to construct healthcheck URI', failure: true, rsp: nil)
      end

      context 'with a valid IIIF base URI' do
        include_context 'with a valid IIIF base_uri'
        it 'returns a failure when the GET request is not successful' do
          response = instance_double('Faraday::Response',
                                     success?: false,
                                     status: 503,
                                     headers: {})

          allow(connection).to receive(:get).with(test_uri).and_return(response)

          result = check.send(:perform_request)

          expect(result[:failure]).to be(true)
          expect(result[:message]).to match(/returned status 503/)
        end

        it 'returns ok when reachable and ACAO header present' do
          response = instance_double('Faraday::Response',
                                     success?: true,
                                     status: 200,
                                     headers: { 'Access-Control-Allow-Origin' => '*' })

          allow(connection).to receive(:get).with(test_uri).and_return(response)

          result = check.send(:perform_request)

          expect(result).to eq(message: 'HTTP check successful', failure: false, rsp: response)
        end
      end
    end
  end
end
