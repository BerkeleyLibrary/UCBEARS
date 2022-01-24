Rails.application.routes.draw do
  root 'items#index'

  defaults format: 'json' do
    get 'health', to: 'health#index'
  end

  # Omniauth automatically handles requests to /auth/:provider. We need only
  # implement the callback.
  get '/login', to: 'sessions#new', as: :login
  get '/logout', to: 'sessions#destroy', as: :logout
  get '/auth/:provider/callback', to: 'sessions#callback', as: :omniauth_callback
  get '/auth/failure', to: 'sessions#failure'

  defaults format: 'csv' do
    get '/stats/lending(/:date)', to: 'stats#download', as: :stats_download
    # TODO: don't include this in production
    get '/stats/all_loan_dates', to: 'stats#all_loan_dates', as: :stats_all_loan_dates
  end

  resources :items, only: :index # index supports both HTML and JSON
  resources :items, except: :index, defaults: { format: 'json' }, constraints: ->(req) { req.format == :json }

  resources :terms, only: :index # index supports both HTML and JSON
  resources :terms, only: %i[index show create update destroy], defaults: { format: 'json' }, constraints: ->(req) { req.format == :json }

  # Shared constraints
  valid_dirname = { directory: Lending::PathUtils::DIRNAME_RAW_RE }

  defaults format: 'html' do
    # TODO: don't include this in production
    get '/stats', to: 'stats#index', as: :stats
    get '/profile_stats', to: 'stats#profile_index', as: :stats_profile

    # TODO: don't include this in production
    get '/profile_index', to: 'lending#profile_index', as: :lending_profile_index

    get '/index', to: 'lending#index', as: :index

    get '/:directory/edit', to: 'lending#edit', as: :lending_edit, constraints: valid_dirname
    get '/:directory', to: 'lending#show', as: :lending_show, constraints: valid_dirname
    get '/:directory/view(/:token)', to: 'lending#view', as: :lending_view, constraints: valid_dirname.merge({ token: %r{[^/]+} })
    patch '/:directory', to: 'lending#update', as: :lending_update, constraints: valid_dirname
    delete '/:directory', to: 'lending#destroy', as: :lending_destroy, constraints: valid_dirname
    # TODO: something more RESTful
    get '/:directory/checkout', to: 'lending#check_out', as: :lending_check_out, constraints: valid_dirname
    get '/:directory/return', to: 'lending#return', as: :lending_return, constraints: valid_dirname
    get '/:directory/activate', to: 'lending#activate', as: :lending_activate, constraints: valid_dirname
    get '/:directory/deactivate', to: 'lending#deactivate', as: :lending_deactivate, constraints: valid_dirname
    get '/:directory/reload', to: 'lending#reload', as: :lending_reload, constraints: valid_dirname
  end

  # TODO: get Rails to use :directory as the primary key and this all gets a lot simpler
  defaults format: 'json' do
    get '/:directory/manifest', to: 'lending#manifest', as: :lending_manifest, constraints: valid_dirname
  end
end
