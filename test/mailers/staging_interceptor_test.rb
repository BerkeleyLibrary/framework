require 'test_helper'
require Rails.root.join('app/mailers/interceptors/staging_interceptor')

class StagingInterceptorTest < ActionMailer::TestCase
  def test_it_routes_mail_to_listserve
    email = RequestMailer.confirmation_email('foo@noemail.com')
    StagingInterceptor.delivering_email(email)

    assert_equal ['lib-testmail@lists.berkeley.edu'], email.to
    assert_equal 'foo@noemail.com', email.header['X-Original-To'].value
  end
end
