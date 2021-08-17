Rails.application.routes.draw do
  root to: redirect('/forms/altmedia/new')

  get 'admin', to: 'home#admin'
  get 'health', to: 'home#health'
  get 'home', to: 'home#index'

  resources :campus_networks, path: 'campus-networks'
  resources :lbl_networks, path: 'lbl-networks'

  scope(:forms) do
    resources :doemoff_study_room_use_forms, path: 'doemoff-study-room-use'
    resources :scan_request_forms, path: 'altmedia'
    resources :affiliate_borrow_request_forms, path: 'berkeley-affiliate-borrowing-card'
    resources :libstaff_edevices_loan_forms, path: 'library-staff-devices'
    resources :service_article_request_forms, path: 'altmedia-articles'
    resources :student_edevices_loan_forms, path: 'student_edevices_loan'
    resources :galc_request_forms, path: 'galc-agreement'
    resources :proxy_borrower_forms, path: 'proxy-borrower', only: [:index]
    resources :stack_requests, path: 'stack-requests', only: [:index]
    resources :stack_pass_forms, path: 'stack-pass'
    resources :reference_card_forms, path: 'reference-card'
  end

  # Fines/Fees Routes:
  get '/fines', to: 'fines#index'
  get '/fines/transaction_fail', to: 'fines#transaction_fail'
  get '/fines/transaction_error', to: 'fines#transaction_error'
  get '/fines/transaction_cancel', to: 'fines#transaction_cancel'
  post '/fines/payment', to: 'fines#payment'
  post '/fines/transaction_complete', to: 'fines#transaction_complete'

  # Mirador IIIF viewer
  mount MiradorRails::Engine, at: MiradorRails::Engine.locales_mount_path

  # Lending (UC BEARS) routes
  # TODO: get Rails to use :directory as the primary key and this all gets a lot simpler
  scope :lending, { format: 'json' } do
    get '/:directory/manifest', to: 'lending#manifest', as: :lending_manifest
  end
  scope :lending, { format: 'html' } do
    get '/', to: 'lending#index', as: :lending
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

  # Proxy Borrower Admin Routes:
  get '/forms/proxy-borrower/admin', to: 'proxy_borrower_admin#admin'
  get '/forms/proxy-borrower/admin_view', to: 'proxy_borrower_admin#admin_view'
  get '/forms/proxy-borrower/admin_export', to: 'proxy_borrower_admin#admin_export'
  get '/forms/proxy-borrower/admin_search', to: 'proxy_borrower_admin#admin_search'
  get '/forms/proxy-borrower/admin_users', to: 'proxy_borrower_admin#admin_users'
  post '/forms/proxy-borrower/add_admin', to: 'proxy_borrower_admin#add_admin'
  patch '/forms/proxy-borrower/update_admin', to: 'proxy_borrower_admin#update_admin', as: :forms_proxy_borrower_update_admin
  delete '/forms/proxy-borrower/delete_admin/:id(.:format)', to: 'proxy_borrower_admin#destroy_admin', as: :forms_proxy_borrower_delete_admin

  # Stack Pass Admin Routes:
  get '/forms/stack-pass-admin/', to: 'stack_pass_admin#admin'
  get '/forms/stack-pass-admin/stack-passes', to: 'stack_pass_admin#stackpasses'
  get '/forms/stack-pass-admin/reference-cards', to: 'stack_pass_admin#refcards'
  get '/forms/stack-pass-admin/users', to: 'stack_pass_admin#users'
  post '/forms/stack-pass-admin/add_user', to: 'stack_pass_admin#add_user'
  delete '/forms/stack-pass-admin/delete_user/:id(.:format)', to: 'stack_pass_admin#destroy_user', as: :forms_stack_pass_delete_user

  # Proxy Borrower Form (DSP and Faculty) Routes:
  get '/forms/proxy-borrower/dsp', to: 'proxy_borrower_forms#dsp_form'
  get '/forms/proxy-borrower/faculty', to: 'proxy_borrower_forms#faculty_form'
  post '/forms/proxy-borrower/request_dsp', to: 'proxy_borrower_forms#process_dsp_request'
  post '/forms/proxy-borrower/request_faculty', to: 'proxy_borrower_forms#process_faculty_request'
  get '/forms/proxy-borrower/result', to: 'proxy_borrower_forms#result'
  get '/forms/proxy-borrower/forbidden', to: 'proxy_borrower_forms#forbidden'

  # Omniauth automatically handles requests to /auth/:provider. We need only
  # implement the callback.
  get '/login', to: 'sessions#new', as: :login
  get '/logout', to: 'sessions#destroy', as: :logout
  get '/auth/:provider/callback', to: 'sessions#callback', as: :omniauth_callback
  get '/auth/failure', to: 'sessions#failure'

  # TIND Download Routes
  get '/tind-download', to: 'tind_download#index'
  get '/tind-download/find_collection', to: 'tind_download#find_collection'
  get '/tind-download/download', to: 'tind_download#download'
  post '/tind-download/download', to: 'tind_download#download'
end
