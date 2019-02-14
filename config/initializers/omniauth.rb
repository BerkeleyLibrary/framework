
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
    service_validate_url: '/cas/p3/serviceValidate',
    fetch_raw_info: Proc.new { |strategy, opts, ticket, user_info, rawxml|
      rawxml.empty? ? {} : {
        "berkeleyEduIsMemberOf" => \
          rawxml.xpath('//cas:berkeleyEduIsMemberOf').map(&:text)
      }
    }

  # Override the default 'puts' logger that Omniauth uses.
  OmniAuth.config.logger = Rails.logger
end
