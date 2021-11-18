require 'rails_helper'

RSpec.describe ItemsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/items').to route_to('items#index', format: 'json')
    end

    it 'routes to #show' do
      expect(get: '/items/1').to route_to('items#show', format: 'json', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/items').to route_to('items#create', format: 'json')
    end

    it 'routes to #update via PUT' do
      expect(put: '/items/1').to route_to('items#update', format: 'json', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/items/1').to route_to('items#update', format: 'json', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/items/1').to route_to('items#destroy', format: 'json', id: '1')
    end
  end
end
