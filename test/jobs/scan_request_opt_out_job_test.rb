require 'test_helper'

class ScanRequestOptOutJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    # TODO: This should probably be configurable.
    @admin_email = 'admin@totally-fake.com'

    # Dummy employee data.
    @patron = { email: 'some-patron@totally-fake.com',
                id: '011822839',
                name: 'David Zuckerman' }
  end

  def test_emails_the_patron_and_admins
    assert_emails 2 do
      ScanRequestOptOutJob.perform_now(patron: @patron)
    end

    staff_email, patron_email = RequestMailer.deliveries.last(2)

    assert_equal 'alt-media scanning service opt-out', staff_email.subject
    assert_nil staff_email.to
    assert_includes staff_email.cc, 'admin@totally-fake.com'
    assert_includes staff_email.cc, 'confirm@totally-fake.com'
    assert_nil staff_email.bcc

    assert_equal 'alt-media scanning service opt-out', patron_email.subject
    assert_includes patron_email.to, @patron[:email]
    assert_nil patron_email.cc
    assert_nil staff_email.bcc
  end
end
