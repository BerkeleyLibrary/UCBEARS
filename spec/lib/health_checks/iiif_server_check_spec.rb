# spec/lib/health_checks/iiif_server_check_spec.rb
require 'rails_helper'

RSpec.describe HealthChecks::IIIFServerCheck do
  subject(:check) { described_class.new }

  def run_check
    check.run
    check
  end

  def stub_items(active_first:, inactive_first:)
    active_relation = instance_double('ActiveRelation', first: active_first)
    inactive_relation = instance_double('InactiveRelation', first: inactive_first)

    allow(Item).to receive(:active).and_return(active_relation)
    allow(Item).to receive(:inactive).and_return(inactive_relation)
  end

  describe '#check' do
    it 'fails and sets message when the IIIF test uri cannot be constructed' do
      allow(Lending::Config).to receive(:iiif_base_uri).and_return(nil)

      run_check

      expect(check.message).to eq('Unable to construct test image URI')

      if check.respond_to?(:failure?)
        expect(check.failure?).to be(true)
      else
        expect(check.instance_variable_get(:@failure_occurred)).to be(true)
      end
    end

    it 'fails and sets message when the HEAD response is not successful' do
      base_uri = URI('http://example.test/iiif/')
      allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)

      iiif_dir = instance_double('IiifDirectory', first_image_url_path: 'some/path')
      item = instance_double('Item', iiif_directory: iiif_dir)
      stub_items(active_first: item, inactive_first: nil)

      test_uri = 'http://example.test/info.json'
      allow(BerkeleyLibrary::Util::URIs).to receive(:append)
        .with(base_uri, 'some/path', 'info.json')
        .and_return(test_uri)

      response = instance_double('Faraday::Response',
                                 success?: false,
                                 status: 503,
                                 headers: {})

      connection = instance_double('Faraday::Connection')
      allow(Faraday).to receive(:new).and_return(connection)
      allow(connection).to receive(:head).with(test_uri).and_return(response)

      run_check

      expect(check.message).to match(/returned status 503/)

      if check.respond_to?(:failure?)
        expect(check.failure?).to be(true)
      else
        expect(check.instance_variable_get(:@failure_occurred)).to be(true)
      end
    end

    it 'fails and sets message when Access-Control-Allow-Origin header is missing/blank' do
      base_uri = URI('http://example.test/iiif/')
      allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)

      iiif_dir = instance_double('IiifDirectory', first_image_url_path: 'some/path')
      item = instance_double('Item', iiif_directory: iiif_dir)
      stub_items(active_first: item, inactive_first: nil)

      test_uri = 'http://example.test/info.json'
      allow(BerkeleyLibrary::Util::URIs).to receive(:append)
        .with(base_uri, 'some/path', 'info.json')
        .and_return(test_uri)

      response = instance_double('Faraday::Response',
                                 success?: true,
                                 status: 200,
                                 headers: { 'Access-Control-Allow-Origin' => '' })

      connection = instance_double('Faraday::Connection')
      allow(Faraday).to receive(:new).and_return(connection)
      allow(connection).to receive(:head).with(test_uri).and_return(response)

      run_check

      expect(check.message).to eq(
        "HEAD #{test_uri} missing Access-Control-Allow-Origin header"
      )

      if check.respond_to?(:failure?)
        expect(check.failure?).to be(true)
      else
        expect(check.instance_variable_get(:@failure_occurred)).to be(true)
      end
    end

    it 'does not fail when reachable and ACAO header present' do
      base_uri = URI('http://example.test/iiif/')
      allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)

      iiif_dir = instance_double('IiifDirectory', first_image_url_path: 'some/path')
      item = instance_double('Item', iiif_directory: iiif_dir)
      stub_items(active_first: item, inactive_first: nil)

      test_uri = 'http://example.test/info.json'
      allow(BerkeleyLibrary::Util::URIs).to receive(:append)
        .with(base_uri, 'some/path', 'info.json')
        .and_return(test_uri)

      response = instance_double('Faraday::Response',
                                 success?: true,
                                 status: 200,
                                 headers: { 'Access-Control-Allow-Origin' => '*' })

      connection = instance_double('Faraday::Connection')
      allow(Faraday).to receive(:new).and_return(connection)
      allow(connection).to receive(:head).with(test_uri).and_return(response)

      run_check

      expect(check.message).to eq('IIIF server reachable')

      if check.respond_to?(:failure?)
        expect(check.failure?).to be(false)
      else
        expect(check.instance_variable_get(:@failure_occurred)).not_to be(true)
      end
    end

    it 'fails and sets message when an exception is raised' do
      base_uri = URI('http://example.test/iiif/')
      allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)

      iiif_dir = instance_double('IiifDirectory', first_image_url_path: 'some/path')
      item = instance_double('Item', iiif_directory: iiif_dir)
      stub_items(active_first: item, inactive_first: nil)

      test_uri = 'http://example.test/info.json'
      allow(BerkeleyLibrary::Util::URIs).to receive(:append)
        .with(base_uri, 'some/path', 'info.json')
        .and_return(test_uri)

      connection = instance_double('Faraday::Connection')
      allow(Faraday).to receive(:new).and_return(connection)
      allow(connection).to receive(:head).with(test_uri).and_raise(StandardError, 'boom')

      run_check

      expect(check.message).to match('StandardError')

      if check.respond_to?(:failure?)
        expect(check.failure?).to be(true)
      else
        expect(check.instance_variable_get(:@failure_occurred)).to be(true)
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

      it 'returns nil when no Item exists' do
        allow(Lending::Config).to receive(:iiif_base_uri).and_return(URI('http://example.test/iiif/'))
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

    describe '#validate_iiif_server' do
      it 'returns a failure when it cannot construct test uri' do
        allow(Lending::Config).to receive(:iiif_base_uri).and_return(nil)

        result = check.send(:validate_iiif_server)

        expect(result).to eq(message: 'Unable to construct test image URI', failure: true)
      end

      it 'returns a failure when the HEAD response is not successful' do
        base_uri = URI('http://example.test/iiif/')
        allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)

        iiif_dir = instance_double('IiifDirectory', first_image_url_path: 'some/path')
        item = instance_double('Item', iiif_directory: iiif_dir)
        stub_items(active_first: item, inactive_first: nil)

        test_uri = 'http://example.test/info.json'
        allow(BerkeleyLibrary::Util::URIs).to receive(:append)
          .with(base_uri, 'some/path', 'info.json')
          .and_return(test_uri)

        response = instance_double('Faraday::Response',
                                   success?: false,
                                   status: 503,
                                   headers: {})

        connection = instance_double('Faraday::Connection')
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:head).with(test_uri).and_return(response)

        result = check.send(:validate_iiif_server)

        expect(result[:failure]).to be(true)
        expect(result[:message]).to match(/returned status 503/)
      end

      it 'returns a failure when Access-Control-Allow-Origin header is missing/blank' do
        base_uri = URI('http://example.test/iiif/')
        allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)

        iiif_dir = instance_double('IiifDirectory', first_image_url_path: 'some/path')
        item = instance_double('Item', iiif_directory: iiif_dir)
        stub_items(active_first: item, inactive_first: nil)

        test_uri = 'http://example.test/info.json'
        allow(BerkeleyLibrary::Util::URIs).to receive(:append)
          .with(base_uri, 'some/path', 'info.json')
          .and_return(test_uri)

        response = instance_double('Faraday::Response',
                                   success?: true,
                                   status: 200,
                                   headers: { 'Access-Control-Allow-Origin' => '' })

        connection = instance_double('Faraday::Connection')
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:head).with(test_uri).and_return(response)

        result = check.send(:validate_iiif_server)

        expect(result).to eq(
          message: "HEAD #{test_uri} missing Access-Control-Allow-Origin header",
          failure: true
        )
      end

      it 'returns ok when reachable and ACAO header present' do
        base_uri = URI('http://example.test/iiif/')
        allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)

        iiif_dir = instance_double('IiifDirectory', first_image_url_path: 'some/path')
        item = instance_double('Item', iiif_directory: iiif_dir)
        stub_items(active_first: item, inactive_first: nil)

        test_uri = 'http://example.test/info.json'
        allow(BerkeleyLibrary::Util::URIs).to receive(:append)
          .with(base_uri, 'some/path', 'info.json')
          .and_return(test_uri)

        response = instance_double('Faraday::Response',
                                   success?: true,
                                   status: 200,
                                   headers: { 'Access-Control-Allow-Origin' => '*' })

        connection = instance_double('Faraday::Connection')
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:head).with(test_uri).and_return(response)

        result = check.send(:validate_iiif_server)

        expect(result).to eq(message: 'IIIF server reachable', failure: false)
      end
    end
  end
end
