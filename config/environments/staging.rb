require Rails.root.join('config/environments/production')
require Rails.root.join('app/mailers/interceptors/staging_interceptor')

Rails.application.configure do |config|
  ActionMailer::Base.register_interceptor(StagingInterceptor)
end
