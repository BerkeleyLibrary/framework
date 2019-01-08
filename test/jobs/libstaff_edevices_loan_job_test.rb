require 'shellwords'
require 'test_helper'

class LibstaffEdevicesLoanJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    # Dummy employee data.
    @patron = { email: 'some-patron@totally-fake.com',
                id: '019999944',
                name: 'Testy Testerson' }
  end

  def test_emails_the_patron_on_success
    assert_emails 1 do
      with_stubbed_ssh(:succeeded) do
        LibstaffEdevicesLoanJob.perform_now(patron: @patron)
      end
    end

    patron_email = RequestMailer.deliveries.last

    assert_email patron_email,
      subject: 'Libdevice confirmation email',
      to: [@patron[:email]]
  end

  def test_send_failure_email_on_ssh_error
    assert_emails 1 do
      assert_raises StandardError do
        with_stubbed_ssh(:raised) do
          LibstaffEdevicesLoanJob.perform_now(patron: @patron)
        end
      end
    end

    assert_email RequestMailer.deliveries.last,
      subject: 'Libdevice failure email',
      to: ['prntscan@lists.berkeley.edu']
  end

  def test_send_failure_email_on_script_error
    assert_emails 1 do
      assert_raises StandardError do
        with_stubbed_ssh(:failed) do
          LibstaffEdevicesLoanJob.perform_now(patron: @patron)
        end
      end
    end

    assert_email RequestMailer.deliveries.last,
      subject: 'Libdevice failure email',
      to: ['prntscan@lists.berkeley.edu']
  end
end
