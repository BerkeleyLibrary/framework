Rails.application.routes.draw do
  root to: redirect('/forms/altmedia/new')

  get 'home', to: 'home#index'

  scope(:forms) do
    resources :scan_request_forms, path: 'altmedia'
    resources :ucop_borrow_request_forms, path: 'ucop-borrowing-card'
  end

  devise_for :users, controllers: { omniauth_callbacks: 'omniauth_callbacks' }

  devise_scope :user do
    get "sign_in", to: "sessions#new", as: :new_user_session
    get "sign_out", to: "sessions#destroy", as: :destroy_user_session
  end
end
