require 'shellwords'
require 'test_helper'

class ScanRequestOptInJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    # Dummy employee data.
    @patron = { email: 'some-patron@totally-fake.com',
                id: '011822839',
                name: 'David Zuckerman' }
  end

  def test_emails_the_patron_on_success
    assert_emails 2 do
      with_stubbed_ssh(:succeeded) do
        ScanRequestOptInJob.perform_now(patron: @patron)
      end
    end

    patron_email, staff_email = RequestMailer.deliveries.last(2)

    assert_email patron_email,
      subject: 'alt-media scanning service opt-in',
      to: [@patron[:email]]

    assert_email staff_email,
      subject: 'alt-media scanning service opt-in',
      cc: %w(prntscan@lists.berkeley.edu baker@library.berkeley.edu)
  end

  def test_send_failure_email_on_ssh_error
    assert_emails 1 do
      assert_raises StandardError do
        with_stubbed_ssh(:raised) do
          ScanRequestOptInJob.perform_now(patron: @patron)
        end
      end
    end

    assert_email RequestMailer.deliveries.last,
      subject: 'alt-media scanning patron opt-in failure',
      to: ['prntscan@lists.berkeley.edu']
  end

  def test_send_failure_email_on_script_error
    assert_emails 1 do
      assert_raises StandardError do
        with_stubbed_ssh(:failed) do
          ScanRequestOptInJob.perform_now(patron: @patron)
        end
      end
    end

    assert_email RequestMailer.deliveries.last,
      subject: 'alt-media scanning patron opt-in failure',
      to: ['prntscan@lists.berkeley.edu']
  end
end
