require 'berkeley_library/alma'

RSpec.configure do |config|
  config.before(:each) do
    BerkeleyLibrary::Alma::Config.default!
    stub_request(:get, /#{BerkeleyLibrary::Alma::Config.alma_sru_base_uri}.*/)
      .to_return(status: 200, body: File.read('spec/data/alma/sru-empty-response.xml'))
  end

  config.after(:each) do
    BerkeleyLibrary::Alma::Config.send(:clear!)
  end
end

def sru_url_for(record_id)
  rec_id = BerkeleyLibrary::Alma::RecordId.parse(record_id)
  raise ArgumentError, "Unknown record ID type: #{record_id}" unless rec_id

  rec_id.marc_uri
end

def sru_data_path_for(record_id)
  "spec/data/alma/#{record_id}-sru.xml"
end

def stub_sru_request(record_id)
  rec_id = record_id.downcase
  sru_url = sru_url_for(rec_id)
  marc_xml_path = sru_data_path_for(rec_id)

  stub_request(:get, sru_url).to_return(status: 200, body: File.read(marc_xml_path))
end
