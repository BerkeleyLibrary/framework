require 'test_helper'

class DoemoffStudyRoomUseJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup { VCR.insert_cassette 'patrons' }
  teardown { VCR.eject_cassette }

  def test_emails_the_patron_on_success
    assert_emails 1 do
      with_stubbed_ssh(:succeeded) do
        DoemoffStudyRoomUseJob.perform_now('012158720')
      end
    end

    patron_email = RequestMailer.deliveries.last

    assert_email patron_email,
      subject: 'Doemoff room confirmation email',
      to: ['danschmidt5189@berkeley.edu']
  end

  def test_send_failure_email_on_ssh_error
    assert_emails 1 do
      assert_raises StandardError do
        with_stubbed_ssh(:raised) do
          DoemoffStudyRoomUseJob.perform_now('012158720')
        end
      end
    end

    assert_email RequestMailer.deliveries.last,
      subject: 'Doemoff room failure email',
      to: ['prntscan@lists.berkeley.edu']
  end

  def test_send_failure_email_on_script_error
    assert_emails 1 do
      assert_raises StandardError do
        with_stubbed_ssh(:failed) do
          DoemoffStudyRoomUseJob.perform_now('012158720')
        end
      end
    end

    assert_email RequestMailer.deliveries.last,
      subject: 'Doemoff room failure email',
      to: ['prntscan@lists.berkeley.edu']
  end
end
