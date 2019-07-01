require 'test_helper'

class ServiceArticleRequestJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup { VCR.insert_cassette 'patrons' }
  teardown { VCR.eject_cassette }

  def test_email_success
    perform_enqueued_jobs do
      ServiceArticleRequestJob.perform_now(
        "lib-testmail@lists.berkeley.edu",
        {
          pub_title: "J Malarial Stud",
          pub_location: "London",
          issn: "12345678",
          vol: "4",
          article_title: "The epidemiology of rat-based vector diseases",
          author: "Dr Testperson",
          pages: "212-59",
          citation: "Testperson, K. The epidemiology of rat-based vector diseases. J Malarial Stud. London: (4) 212-59.",
          pub_notes: "Cannot be retrieved in English",
        },
        '012158720',
      )
    end

    test_email = RequestMailer.deliveries.last
    assert_email test_email,
      subject: 'Alt-Media Service - Article Request',
      to: ["lib-testmail@lists.berkeley.edu"]
  end
end
