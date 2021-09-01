Rails.application.routes.draw do
  root 'lending#index', as: :index

  get 'health', to: 'home#health'

  # Mirador IIIF viewer
  mount MiradorRails::Engine, at: MiradorRails::Engine.locales_mount_path

  # Omniauth automatically handles requests to /auth/:provider. We need only
  # implement the callback.
  get '/login', to: 'sessions#new', as: :login
  get '/logout', to: 'sessions#destroy', as: :logout
  get '/auth/:provider/callback', to: 'sessions#callback', as: :omniauth_callback
  get '/auth/failure', to: 'sessions#failure'

  # Lending (UC BEARS) routes
  # TODO: get Rails to use :directory as the primary key and this all gets a lot simpler
  defaults format: 'json' do
    get '/:directory/manifest', to: 'lending#manifest', as: :lending_manifest, constraints: { directory: %r{[^/]+} }
  end

  defaults format: 'html' do
    # TODO: don't include this in production
    get '/profile', to: 'lending#profile', as: :lending_profile

    get '/stats', to: 'lending#stats', as: :lending_stats

    get '/:directory/edit', to: 'lending#edit', as: :lending_edit, constraints: { directory: %r{[^/]+} }
    get '/:directory', to: 'lending#show', as: :lending_show, constraints: { directory: %r{[^/]+} }
    get '/:directory/view(/:token)', to: 'lending#view', as: :lending_view, constraints: { directory: %r{[^/]+}, token: %r{[^/]+} }
    patch '/:directory', to: 'lending#update', as: :lending_update, constraints: { directory: %r{[^/]+} }
    delete '/:directory', to: 'lending#destroy', as: :lending_destroy, constraints: { directory: %r{[^/]+} }
    # TODO: something more RESTful
    get '/:directory/checkout', to: 'lending#check_out', as: :lending_check_out, constraints: { directory: %r{[^/]+} }
    get '/:directory/return', to: 'lending#return', as: :lending_return, constraints: { directory: %r{[^/]+} }
    get '/:directory/activate', to: 'lending#activate', as: :lending_activate, constraints: { directory: %r{[^/]+} }
    get '/:directory/deactivate', to: 'lending#deactivate', as: :lending_deactivate, constraints: { directory: %r{[^/]+} }
    get '/:directory/reload', to: 'lending#reload', as: :lending_reload, constraints: { directory: %r{[^/]+} }
  end

end
