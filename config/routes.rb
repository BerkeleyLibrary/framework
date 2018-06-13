Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'scan#hello'

#  get 'scanrequest', to: "scan#scanrequest"
  post 'scanrequest', to: "scan#scanrequest"
  get 'scan/entry'
  get 'scan/notfaculty'
  get 'scan/blocked'
  get 'scan/optout'
  get 'scan/optin'

end
