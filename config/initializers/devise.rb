Devise.setup do |config|
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 11
  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true
  config.sign_out_via = :get

  config.omniauth :cas,
    name: :calnet,
    host: "auth#{'-test' unless Rails.env.production?}.berkeley.edu",
    login_url: '/cas/login',
    service_validate_url: '/cas/p3/serviceValidate'

  OmniAuth.config.logger = Rails.logger
end
