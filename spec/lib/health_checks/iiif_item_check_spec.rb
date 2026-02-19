require 'rails_helper'
require 'support/iiif_check_helper'

RSpec.describe HealthChecks::IIIFItemCheck do
  subject(:check) { described_class.new }

  def run_check
    check.run
    check
  end

  describe '#check' do

    context 'with a valid IIIF base URI' do
      include_context 'IIIF item checks'

      it 'fails and sets message when the GET health check response is not successful' do
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

      it 'fails and sets message when Access-Control-Allow-Origin header is missing/blank' do
        response = instance_double('Faraday::Response',
                                   success?: true,
                                   status: 200,
                                   headers: { 'Access-Control-Allow-Origin' => '' })

        allow(connection).to receive(:get).with(test_uri).and_return(response)

        run_check

        expect(check.message).to eq(
          "GET #{test_uri} missing Access-Control-Allow-Origin header"
        )

        if check.respond_to?(:failure?)
          expect(check.failure?).to be(true)
        else
          expect(check.instance_variable_get(:@failure_occurred)).to be(true)
        end
      end

      it 'does not fail when reachable and ACAO header present' do
        response = instance_double('Faraday::Response',
                                   success?: true,
                                   status: 200,
                                   headers: { 'Access-Control-Allow-Origin' => '*' })

        allow(connection).to receive(:get).with(test_uri).and_return(response)

        run_check

        expect(check.message).to eq('HTTP check successful')

        if check.respond_to?(:failure?)
          expect(check.failure?).to be(false)
        else
          expect(check.instance_variable_get(:@failure_occurred)).not_to be(true)
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

    describe '#iiif_base_uri' do
      it 'returns nil when iiif_base_uri is nil' do
        allow(Lending::Config).to receive(:iiif_base_uri).and_return(nil)

        expect(check.send(:iiif_base_uri)).to be_nil
      end

      it 'returns the Lending::Config value when set' do
        allow(Lending::Config).to receive(:iiif_base_uri).and_return('http://example.test/iiif')
        expect(check.send(:iiif_base_uri)).to eq('http://example.test/iiif')
      end
    end

    describe '#iiif_test_uri' do
      it 'returns nil when iiif_base_uri is nil' do
        allow(Lending::Config).to receive(:iiif_base_uri).and_return(nil)

        expect(check.send(:iiif_test_uri)).to be_nil
      end

      context 'with IIIF item checks' do
        include_context 'IIIF item checks'

        it 'returns nil when no Item exists' do
          allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)
          stub_items(active_first: nil, inactive_first: nil)

          expect(check.send(:iiif_test_uri)).to be_nil
        end

        it 'builds a test uri from an active item (or inactive fallback)' do
          base_uri = URI('http://example.test/iiif/')
          allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)

          iiif_dir = instance_double('IiifDirectory', first_image_url_path: 'some/path')
          item = instance_double('Item', iiif_directory: iiif_dir)
          stub_items(active_first: item, inactive_first: nil)

          expect(BerkeleyLibrary::Util::URIs).to receive(:append)
            .with(base_uri, 'some/path', 'info.json')
            .and_return('http://example.test/iiif/some/path/info.json')

          expect(check.send(:iiif_test_uri)).to eq('http://example.test/iiif/some/path/info.json')
        end
      end
    end

    describe '#perform_request' do
      it 'returns a failure when it cannot construct test uri' do
        allow(Lending::Config).to receive(:iiif_base_uri).and_return(nil)

        result = check.send(:perform_request)

        expect(result).to eq(message: 'Unable to construct healthcheck URI', failure: true, rsp: nil)
      end

      context 'with IIIF item checks' do
        include_context 'IIIF item checks'
        it 'returns a failure when the GET response is not successful' do
          response = instance_double('Faraday::Response',
                                     success?: false,
                                     status: 503,
                                     headers: {})

          allow(connection).to receive(:get).with(test_uri).and_return(response)

          result = check.send(:perform_request)

          expect(result[:failure]).to be(true)
          expect(result[:message]).to match(/returned status 503/)
        end

        it 'returns a failure when Access-Control-Allow-Origin header is missing/blank' do
          response = instance_double('Faraday::Response',
                                     success?: true,
                                     status: 200,
                                     headers: { 'Access-Control-Allow-Origin' => '' })

          allow(connection).to receive(:get).with(test_uri).and_return(response)

          result = check.send(:perform_request)

          expect(result).to eq(
            message: "GET #{test_uri} missing Access-Control-Allow-Origin header",
            failure: true,
            rsp: response
          )
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
