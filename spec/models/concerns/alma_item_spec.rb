require 'rails_helper'

describe AlmaItem do
  let(:mms_ids_by_factory) do
    {
      active_item: '991044006109706532',
      complete_item: '991044762619706532'
    }
  end

  attr_reader :items_by_mms_id

  before do
    @items_by_mms_id = mms_ids_by_factory.to_h do |factory, id|
      mms_id = BerkeleyLibrary::Alma::RecordId.parse(id)
      [mms_id, create(factory)]
    end

    items_by_mms_id.each_value do |item|
      stub_sru_request(item.record_id)
    end
  end

  describe :alma_mms_id do
    it 'returns the MMS ID' do
      items_by_mms_id.each do |mms_id, item|
        expect(item.alma_mms_id).to eq(mms_id)
      end
    end
  end

  describe :alma_permalink do
    it 'returns the permalink' do
      items_by_mms_id.each do |mms_id, item|
        expected_permalink = mms_id.permalink_uri
        expect(item.alma_permalink).to eq(expected_permalink)
      end
    end
  end
end
