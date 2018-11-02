require 'test_helper'
require Rails.root.join('app/mailers/interceptor/mailing_list_interceptor')

class MailingListInterceptorTest < ActionMailer::TestCase
  setup do
    @interceptor = Interceptor::MailingListInterceptor.new('foo@noemail.com')
  end

  def test_responds_to_delivering_email
    assert_respond_to @interceptor, :delivering_email
  end

  def test_it_routes_mail_to_desired_listserve
    email = Mail.new do
      subject 'Framework/Mission Control Test Email'
      to %w(danschmidt5189@berkeley.edu dcschmidt@berkeley.edu)
      cc %w(ghill@library.berkeley.edu ethomas@berkeley.edu)
      bcc 'tparks@library.berkeley.edu'
    end

    @interceptor.delivering_email(email)
    assert_equal %w(foo@noemail.com), email.to
    assert_equal "danschmidt5189@berkeley.edu, dcschmidt@berkeley.edu", email.header['X-Original-To'].value
    assert_equal "ghill@library.berkeley.edu, ethomas@berkeley.edu", email.header['X-Original-CC'].value
    assert_equal "tparks@library.berkeley.edu", email.header['X-Original-BCC'].value
  end
end
