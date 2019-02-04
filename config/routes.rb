Rails.application.routes.draw do
  root to: redirect('/forms/altmedia/new')

  get 'home', to: 'home#index'

  resources :campus_networks, path: 'campus-networks'

  scope(:forms) do
    resources :scan_request_forms, path: 'altmedia'
    resources :ucop_borrow_request_forms, path: 'ucop-borrowing-card'
    resources :libstaff_edevices_loan_forms, path: 'library-staff-devices'
    resources :service_article_request_forms, path: 'altmedia-articles'
  end

  # Omniauth automatically handles requests to /auth/:provider. We need only
  # implement the callback.
  get '/login', to: 'sessions#new', as: :login
  get '/logout', to: 'sessions#destroy', as: :logout
  get '/auth/:provider/callback', to: 'sessions#callback', as: :omniauth_callback
  get '/auth/failure', to: 'sessions#failure'
end
