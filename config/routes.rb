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
    resources :ucop_borrow_request_forms, path: 'ucop-borrowing-card'
    resources :libstaff_edevices_loan_forms, path: 'library-staff-devices'
    resources :service_article_request_forms, path: 'altmedia-articles'
    resources :student_edevices_loan_forms, path: 'student_edevices_loan'
    resources :galc_request_forms, path: 'galc-agreement'
    resources :proxy_borrower_forms, path: 'proxy-borrower', only: [:index]
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
end
