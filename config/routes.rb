Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'sessions#new'
  
  devise_for :users, controllers: { omniauth_callbacks: "omniauth_callbacks" }

  devise_scope :user do
    get "sign_in", to: "sessions#new", as: :new_user_session
    get "sign_out", to: "sessions#destroy", as: :destroy_user_session
  end


#  get 'scanrequest', to: "scan#scanrequest"
  post 'scanrequest', to: "scan#scanrequest"
  get 'scan/entry'
  get 'scan/notfaculty'
  get 'scan/blocked'
  get 'scan/optout'
  get 'scan/optin'
   
end
