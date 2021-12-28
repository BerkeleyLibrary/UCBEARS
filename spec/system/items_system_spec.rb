require 'rails_helper'

describe ItemsController, type: :system do
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
    # NOTE: we're deliberately not validating here, because we want some invalid items
    @items = factory_names.each_with_object([]) do |fn, items|
      items << build(fn).tap { |it| it.save!(validate: false) }
    end
  end

  context 'with lending admin credentials' do
    before(:each) { mock_login(:lending_admin) }
    after(:each) { logout! }

    describe :index do

      it 'displays the items' do
        visit items_path

        expected_count = [Item.count, Pagy::DEFAULT[:items]].min
        expected_items = Item.take(expected_count)
        expect(expected_items).not_to be_empty

        expected_items.each do |item|
          expect(page).to have_content(item.title)
        end
      end
    end
  end
end
