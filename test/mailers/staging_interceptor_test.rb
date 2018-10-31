require 'test_helper'
require Rails.root.join('app/mailers/interceptors/staging_interceptor')

class StagingInterceptorTest < ActionMailer::TestCase
  setup do
    @original_to_email = StagingInterceptor.to_email
    StagingInterceptor.to_email = 'foo-email@noemail.foobar'
  end

  teardown do
    StagingInterceptor.to_email = @original_to_email
  end

  def test_to_email_is_configurable
    assert_equal 'lib-testmail@lists.berkeley.edu', @original_to_email
    assert_equal 'foo-email@noemail.foobar', StagingInterceptor.to_email
    assert_equal 'foo-email@noemail.foobar', StagingInterceptor.new.to_email
  end

  def test_it_routes_mail_to_desired_listserve
    email = Mail.new do
      subject 'Framework/Mission Control Test Email'
      to %w(danschmidt5189@berkeley.edu dcschmidt@berkeley.edu)
      cc %w(ghill@library.berkeley.edu ethomas@berkeley.edu)
      bcc 'tparks@library.berkeley.edu'
    end

    StagingInterceptor.delivering_email(email)

    assert_equal %w(foo-email@noemail.foobar), email.to
    assert_equal "danschmidt5189@berkeley.edu, dcschmidt@berkeley.edu", email.header['X-Original-To'].value
    assert_equal "ghill@library.berkeley.edu, ethomas@berkeley.edu", email.header['X-Original-CC'].value
    assert_equal "tparks@library.berkeley.edu", email.header['X-Original-BCC'].value
  end
end
