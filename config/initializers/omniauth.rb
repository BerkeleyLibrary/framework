
Rails.application.config.middleware.use OmniAuth::Builder do
  # The "developer" strategy is a dummy strategy used in testing. To use it,
  # start the app and visit /auth/developer. You'll be presented with a form
  # that allows you to enter the listed User attributes.
  if not Rails.env.production?
    provider :developer,
      :fields => [:uid, :display_name, :employee_id],
      :uid_field => :uid
  end

  # omniauth-cas provides integration with Calnet.
  provider :cas,
    name: :calnet,
    host: "auth#{'-test' unless Rails.env.production?}.berkeley.edu",
    login_url: '/cas/login',
    logout_url: "https://auth.berkeley.edu/cas/logout",
    service_validate_url: '/cas/p3/serviceValidate'

  # Override the default 'puts' logger that Omniauth uses.
  OmniAuth.config.logger = Rails.logger
end
