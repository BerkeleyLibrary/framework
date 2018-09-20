require 'shellwords'
require 'test_helper'

class ScanRequestOptInJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    # TODO: This should probably be configurable.
    @admin_email = 'admin@totally-fake.com'

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

    assert_equal patron_email.subject, 'alt-media scanning service opt-in'
    assert_includes patron_email.to, @patron[:email]

    assert_equal staff_email.subject, 'alt-media scanning service opt-in'
    assert_includes staff_email.cc, 'admin@totally-fake.com'
    assert_includes staff_email.cc, 'confirm@totally-fake.com'
  end

  def test_send_failure_email_on_ssh_error
    assert_emails 1 do
      assert_raises StandardError do
        with_stubbed_ssh(:raised) do
          ScanRequestOptInJob.perform_now(patron: @patron)
        end
      end
    end

    email = RequestMailer.deliveries.last

    assert_includes email.to, @admin_email
    assert_equal 'alt-media scanning patron opt-in failure', email.subject
  end

  def test_send_failure_email_on_script_error
    assert_emails 1 do
      assert_raises StandardError do
        with_stubbed_ssh(:failed) do
          ScanRequestOptInJob.perform_now(patron: @patron)
        end
      end
    end

    email = RequestMailer.deliveries.last

    assert_includes email.to, @admin_email
    assert_equal 'alt-media scanning patron opt-in failure', email.subject
  end
end
