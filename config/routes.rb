Rails.application.routes.draw do
  root to: redirect('/forms/altmedia/new')

  get 'admin', to: 'home#admin'
  get 'health', to: 'ok_computer/ok_computer#index', defaults: { format: :json }
  get 'home', to: 'home#index'
  get 'build_info', to: 'home#build_info'

  defaults format: :text do
    resources :campus_networks, path: 'campus-networks', only: :index
    resources :lbl_networks, path: 'lbl-networks', only: :index # TODO: is this used?
  end

  scope(:forms) do
    resources :doemoff_study_room_use_forms, path: 'doemoff-study-room-use'
    resources :scan_request_forms, path: 'altmedia'
    resources :affiliate_borrow_request_forms, path: 'berkeley-affiliate-borrowing-card'
    resources :libstaff_edevices_loan_forms, path: 'library-staff-devices'
    resources :service_article_request_forms, path: 'altmedia-articles'
    resources :student_edevices_loan_forms, path: 'student_edevices_loan'
    resources :galc_request_forms, path: 'galc-agreement'
    resources :doemoff_patron_email_forms, path: 'doemoff-patron-email'
    resources :proxy_borrower_forms, path: 'proxy-borrower', only: [:index]
    resources :security_incident_report_forms, path: 'security-incident-report'
    resources :stack_requests, path: 'stack-requests', only: [:index]
    resources :stack_pass_forms, path: 'stack-pass'
    resources :reference_card_forms, path: 'reference-card'
    resources :departmental_card_forms, path: 'departmental-card'
  end

  # Alma patron validation for proxy
  post '/validate_proxy_patron', to: 'validate_proxy_patron#index'

  # Fees Routes:
  get '/fees', to: 'fees#index'
  get '/fees/transaction_fail', to: 'fees#transaction_fail'
  get '/fees/transaction_error', to: 'fees#transaction_error'
  get '/fees/transaction_cancel', to: 'fees#transaction_cancel'
  post '/fees/payment', to: 'fees#payment'
  post '/fees/transaction_complete', to: 'fees#transaction_complete'

  # Email Fee Invoice:
  # (allows library staff to lookup and send payment instructions)
  get '/efee', to: 'fees#efee'
  get '/efees', to: 'fees#efees'
  get '/efees/lookup', to: 'fees#lookup'
  post '/efees/send_invoice', to: 'fees#send_invoice'

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
  get '/logout', to: 'sessions#destroy', as: :logout
  get '/auth/:provider/callback', to: 'sessions#callback', as: :omniauth_callback
  get '/auth/failure', to: 'sessions#failure'

  # TIND Download Routes
  get '/tind-download', to: 'tind_download#index'
  get '/tind-download/find_collection', to: 'tind_download#find_collection'
  get '/tind-download/download', to: 'tind_download#download'
  post '/tind-download/download', to: 'tind_download#download'

  # Locations
  get '/location_requests/immediate', to: 'location_requests#immediate', as: :immediate_location_request
  get '/location_requests/:id/result', to: 'location_requests#result', as: :location_requests_result
  resources :location_requests

  # http://example.com/good_job
  mount GoodJob::Engine => 'good_job'
  get 'jobs', to: 'good_job/jobs#index'

  # Tind Alma batch load request
  get '/tind-marc-batch', to: 'tind_marc_batch#new'
  post '/tind-marc-batch', to: 'tind_marc_batch#create'

  # Tind Alma batch load test request
  get '/tind-marc-batch-test', to: 'tind_marc_batch_test#new'
  post '/tind-marc-batch-test', to: 'tind_marc_batch_test#create'

  # Tind MMSID Information request
  get '/mmsid-tind', to: 'mmsid_tind#new'
  post '/mmsid-tind', to: 'mmsid_tind#create'

  # Tind validator
  get '/tind-spread-validator', to: 'tind_validator#new'
  post '/tind-spread-validator', to: 'tind_validator#create'

  # Alma Item Set Routes
  get '/alma-item-set', to: 'alma_item_set#index'
  post '/alma-item-set', to: 'alma_item_set#update'

  # bib host file upload
  get '/bibliographics', to: 'bibliographics#new'
  post '/bibliographics', to: 'bibliographics#create'
  get '/bibliographics/response', to: 'bibliographics#response'

end
