require Rails.root.join('config/environments/production')
require Rails.root.join('app/mailers/interceptor/mailing_list_interceptor')

Rails.application.configure do |config|
  # Route emails to a mailing list in staging
  interceptor = Interceptor::MailingListInterceptor.new
  ActionMailer::Base.register_interceptor(interceptor)
end
