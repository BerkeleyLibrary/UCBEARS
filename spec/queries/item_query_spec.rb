require 'rails_helper'

describe ItemQuery do
  let(:factory_names) do
    %i[
      complete_item
      active_item
      incomplete_no_directory
      incomplete_no_images
      incomplete_no_marc
      incomplete_no_manifest
      incomplete_marc_only
    ]
  end

  attr_reader :items

  before(:each) do
    {
      lending_root_path: Pathname.new('spec/data/lending'), iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end

    # NOTE: we're deliberately not validating here, because we want some invalid items
    @items = factory_names.each_with_object({}) do |fn, items|
      items[fn] = build(fn).tap { |it| it.save!(validate: false) }
    end
  end

  it 'can exclude incomplete items' do
    query = ItemQuery.new(complete: true)

    expected_items = Item.all.reject(&:incomplete?)
    expect(expected_items.any?).to eq(true) # just to be sure

    actual_items = query.to_a
    expect(actual_items).to contain_exactly(*expected_items)
  end

  it 'can exclude incomplete items' do
    query = ItemQuery.new(complete: false)

    expected_items = Item.all.select(&:incomplete?)
    expect(expected_items.any?).to eq(true) # just to be sure

    actual_items = query.to_a
    expect(actual_items).to contain_exactly(*expected_items)
  end

  it 'can exclude inactive items' do
    query = ItemQuery.new(active: true)

    expected_items = Item.all.select(&:active?)
    expect(expected_items.any?).to eq(true) # just to be sure

    actual_items = query.to_a
    expect(actual_items).to contain_exactly(*expected_items)
  end

  it 'can exclude active items' do
    query = ItemQuery.new(active: false)

    expected_items = Item.all.reject(&:active?)
    expect(expected_items.any?).to eq(true) # just to be sure

    actual_items = query.to_a
    expect(actual_items).to contain_exactly(*expected_items)
  end

  it 'can filter inactive items by completeness' do
    query = ItemQuery.new(active: false, complete: true)

    expected_items = Item.all.reject(&:active?).select(&:complete?)
    expect(expected_items.any?).to eq(true) # just to be sure

    actual_items = query.to_a
    expect(actual_items).to contain_exactly(*expected_items)
  end
end
