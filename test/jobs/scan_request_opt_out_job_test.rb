require 'test_helper'

class ScanRequestOptOutJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup { VCR.insert_cassette 'patrons' }
  teardown { VCR.eject_cassette }

  def test_emails_the_patron_and_admins
    assert_emails 2 do
      ScanRequestOptOutJob.perform_now('012158720')
    end

    staff_email, patron_email = RequestMailer.deliveries.last(2)

    assert_equal 'alt-media scanning service opt-out', staff_email.subject
    assert_nil staff_email.to
    assert_includes staff_email.cc, 'prntscan@lists.berkeley.edu'
    assert_includes staff_email.cc, 'baker@library.berkeley.edu'
    assert_nil staff_email.bcc

    assert_equal 'alt-media scanning service opt-out', patron_email.subject
    assert_includes patron_email.to, 'danschmidt5189@berkeley.edu'
    assert_nil patron_email.cc
    assert_nil staff_email.bcc
  end
end
