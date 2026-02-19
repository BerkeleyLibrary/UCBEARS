RSpec.configure do |rspec|
  rspec.shared_context_metadata_behavior = :apply_to_host_groups
end

RSpec.shared_context 'with a valid IIIF base_uri', shared_context: :metadata do
  let!(:base_uri) { URI('http://example.test/iiif') }
  let!(:test_uri) { URI('http://example.test/health') }
  let(:connection) { instance_double('Faraday::Connection') }

  before do
    allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)
    allow(URI).to receive(:join)
      .with(base_uri, '/health')
      .and_return(test_uri)
    allow(Faraday).to receive(:new).and_return(connection)
  end

end

RSpec.shared_context 'IIIF item checks', shared_context: :metadata do
  let!(:base_uri) { URI('http://example.test/iiif/') }
  let!(:test_uri) { URI('http://example.test/info.json') }
  let(:iiif_dir) do
    instance_double('IiifDirectory',
                    first_image_url_path: 'some/path')
  end
  let(:item) { instance_double('Item', iiif_directory: iiif_dir) }
  let(:connection) { instance_double('Faraday::Connection') }

  def stub_items(active_first:, inactive_first:)
    active_relation = instance_double('ActiveRelation', first: active_first)
    inactive_relation = instance_double('InactiveRelation', first: inactive_first)

    allow(Item).to receive(:active).and_return(active_relation)
    allow(Item).to receive(:inactive).and_return(inactive_relation)
  end

  before do
    allow(Lending::Config).to receive(:iiif_base_uri).and_return(base_uri)
    stub_items(active_first: item, inactive_first: nil)
    allow(BerkeleyLibrary::Util::URIs).to receive(:append)
      .with(base_uri, 'some/path', 'info.json')
      .and_return(test_uri)
    allow(Faraday).to receive(:new).and_return(connection)
  end

end

RSpec.configure do |rspec|
  rspec.include_context 'with a valid IIIF base_uri', include_shared: true
end
