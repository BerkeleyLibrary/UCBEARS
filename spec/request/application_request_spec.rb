require 'rails_helper'

describe ApplicationController, type: :request do
  it 'hides hidden paths' do
    old_hidden_paths = ENV['LIT_HIDDEN_PATHS']
    begin
      ENV['LIT_HIDDEN_PATHS'] = '/home /adm.*'
      get '/admin'
      expect(response).to have_http_status(:not_found)

      get '/home'
      expect(response).to have_http_status(:not_found)
    ensure
      ENV['LIT_HIDDEN_PATHS'] = old_hidden_paths
    end
  end
end
