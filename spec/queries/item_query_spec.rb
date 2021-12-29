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
    @items = factory_names.each_with_object([]) do |fn, items|
      items << build(fn).tap { |it| it.save!(validate: false) }
    end
  end

  it 'can exclude incomplete items' do
    query = ItemQuery.new(complete: true)

    expected_items = Item.where(complete: true)
    expect(expected_items.any?).to eq(true) # just to be sure

    actual_items = query.to_a
    expect(actual_items).to contain_exactly(*expected_items)
  end

  it 'can exclude complete items' do
    query = ItemQuery.new(complete: false)

    expected_items = Item.where(complete: false)
    expect(expected_items.any?).to eq(true) # just to be sure

    actual_items = query.to_a
    expect(actual_items).to contain_exactly(*expected_items)
  end

  it 'can exclude inactive items' do
    query = ItemQuery.new(active: true)

    expected_items = Item.where(active: true)
    expect(expected_items.any?).to eq(true) # just to be sure

    actual_items = query.to_a
    expect(actual_items).to contain_exactly(*expected_items)
  end

  it 'can exclude active items' do
    query = ItemQuery.new(active: false)

    expected_items = Item.where(active: false)
    expect(expected_items.any?).to eq(true) # just to be sure

    actual_items = query.to_a
    expect(actual_items).to contain_exactly(*expected_items)
  end

  it 'can filter inactive items by completeness' do
    query = ItemQuery.new(active: false, complete: true)

    expected_items = Item.where(active: false).where(complete: true)
    expect(expected_items.any?).to eq(true) # just to be sure

    actual_items = query.to_a
    expect(actual_items).to contain_exactly(*expected_items)
  end

  describe 'filtering by term' do
    attr_reader :term_fall_2021
    attr_reader :term_spring_2022

    before(:each) do
      @term_fall_2021 = create(:term_fall_2021)
      @term_spring_2022 = create(:term_spring_2022)

      items.each_with_index do |it, ix|
        expect(it.terms).to be_empty # just to be sure

        term = ix.even? ? term_fall_2021 : term_spring_2022
        it.terms << term
      end
    end

    it 'can filter by term' do
      query = ItemQuery.new(terms: [term_fall_2021.name])
      expected_items = term_fall_2021.items
      expect(expected_items).not_to be_empty # just to be sure

      expect(query).to contain_exactly(*expected_items)
    end

    it 'can find by multiple terms' do
      query = ItemQuery.new(terms: Term.pluck(:name))
      expect(query).to contain_exactly(*items)
    end

    it 'can handle nonexistent terms' do
      query = ItemQuery.new(terms: ['Not a term', term_spring_2022.name])
      expected_items = term_spring_2022.items
      expect(expected_items).not_to be_empty # just to be sure

      expect(query).to contain_exactly(*expected_items)
    end

    it 'can filter by term with other conditions' do
      query = ItemQuery.new(active: true, complete: false, terms: [term_fall_2021.name])
      expected_items = term_fall_2021.items.incomplete.where(active: true)
      expect(expected_items).not_to be_empty # just to be sure

      expect(query).to contain_exactly(*expected_items)
    end

    it 'can filter by term with keywords' do
      query = ItemQuery.new(active: true, complete: false, keywords: 'depression', terms: [term_fall_2021.name])
      expected_items = term_fall_2021.items.incomplete.where(active: true).where('title LIKE ?', '%depression%')
      expect(expected_items).not_to be_empty # just to be sure

      expect(query).to contain_exactly(*expected_items)
    end
  end
end
