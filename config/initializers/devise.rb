Devise.setup do |config|
require 'devise/orm/active_record'
config.skip_session_storage = [:http_auth]
config.stretches = Rails.env.test? ? 1 : 11
config.reconfirmable = true
config.expire_all_remember_me_on_sign_out = true 
config.sign_out_via = :get

calnet_url = ENV['CALNET_URL'] ? ENV['CALNET_URL']
						: Rails.env.production? ? 'auth.berkeley.edu'
						:													'auth-test.berkeley.edu'

#config.omniauth :cas,name: :altmedia,url: 'https://auth.berkeley.edu/cas/p3/serviceValidate'
config.omniauth :cas,name: :altmedia,host: calnet_url,login_url: '/cas/login',service_validate_url: '/cas/p3/serviceValidate'

end
