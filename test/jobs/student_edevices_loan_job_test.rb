require 'test_helper'

class StudentEdevicesLoanJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    # Dummy patron data.
    @patron = { email: 'some-patron@totally-fake.com',
                id: '0123456789',
                name: 'Testy Testerson' }
  end

  def test_emails_the_patron_on_success
    assert_emails 1 do
      with_stubbed_ssh(:succeeded) do
        StudentEdevicesLoanJob.perform_now(patron: @patron)
      end
    end

    patron_email = RequestMailer.deliveries.last

    assert_email patron_email,
      subject: 'Student edevices confirmation email',
      to: [@patron[:email]]
  end

  def test_send_failure_email_on_ssh_error
    assert_emails 1 do
      assert_raises StandardError do
        with_stubbed_ssh(:raised) do
          StudentEdevicesLoanJob.perform_now(patron: @patron)
        end
      end
    end

    assert_email RequestMailer.deliveries.last,
      subject: 'Student edevices failure email',
      to: ['prntscan@lists.berkeley.edu']
  end

  def test_send_failure_email_on_script_error
    assert_emails 1 do
      assert_raises StandardError do
        with_stubbed_ssh(:failed) do
          StudentEdevicesLoanJob.perform_now(patron: @patron)
        end
      end
    end

    assert_email RequestMailer.deliveries.last,
      subject: 'Student edevices failure email',
      to: ['prntscan@lists.berkeley.edu']
  end
end