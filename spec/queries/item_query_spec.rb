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

  describe :to_s do
    it 'includes all the relevant parameters' do
      term = create(:term_fall_2021)
      keywords = 'some keywords'
      limit = 5
      offset = 12

      query = ItemQuery.new(active: true, complete: false, terms: [term.name], keywords: keywords, limit: limit, offset: offset)
      query_str = query.to_s

      expected_params = ['active', 'incomplete', term.name, keywords, limit.to_s, offset.to_s]
      expected_params.each do |expected_param|
        expect(query_str).to include(expected_param)
      end
    end
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

    it 'does not produce duplicate entries if items are in multiple terms' do
      term_spring_2021 = Term.create(name: 'Spring 2021', start_date: Date.new(2021, 0o1, 12), end_date: Date.new(2021, 5, 14))
      keyword = 'Egypt'

      expected_items = []
      term_names = [term_spring_2021.name]
      Item.where('title LIKE ?', "%#{keyword}%").find_each do |it|
        it.terms.pluck(:name).each { |tn| term_names << tn unless term_names.include?(tn) }
        it.terms << term_spring_2021
        expected_items << it
      end

      query = ItemQuery.new(keywords: keyword, terms: term_names)
      expect(query.count).to eq(expected_items.size)
      expect(query).to contain_exactly(*expected_items)
    end
  end
end
