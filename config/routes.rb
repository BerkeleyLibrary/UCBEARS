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
    get '/:directory/manifest', to: 'lending#manifest', as: :lending_manifest
  end

  defaults format: 'html' do
    post '/', to: 'lending#create'

    get '/profile', to: 'lending#profile', as: :lending_profile

    get '/new', to: 'lending#new', as: :lending_new
    get '/:directory/edit', to: 'lending#edit', as: :lending_edit
    get '/:directory', to: 'lending#show', as: :lending_show
    get '/:directory/view', to: 'lending#view', as: :lending_view
    patch '/:directory', to: 'lending#update', as: :lending_update
    delete '/:directory', to: 'lending#destroy', as: :lending_destroy
    # TODO: something more RESTful
    get '/:directory/checkout', to: 'lending#check_out', as: :lending_check_out
    get '/:directory/return', to: 'lending#return', as: :lending_return
    get '/:directory/activate', to: 'lending#activate', as: :lending_activate
    get '/:directory/deactivate', to: 'lending#deactivate', as: :lending_deactivate
  end

end
