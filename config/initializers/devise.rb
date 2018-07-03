require 'devise/orm/active_record'

Devise.setup do |config|
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 11
  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true
  config.sign_out_via = :get

  calnet_url = ENV.fetch('CALNET_URL') {
    Rails.env.production? ? 'auth.berkeley.edu' : 'auth-test.berkeley.edu'
  }

  config.omniauth :cas,
    name: :altmedia,
    host: calnet_url,
    login_url: '/cas/login',
    service_validate_url: '/cas/p3/serviceValidate'
end
