require 'test_helper'

class ServiceArticleRequestJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    #Dummy employee and article data.
    @patron = { email: 'some-patron@totally-fake.com',
                id: '019999944',
                name: 'Testy Testerson' }
    @support_email = "lib-testmail@lists.berkeley.edu"
    @publication = {
        pub_title: "J Malarial Stud",
        pub_location: "London",
        issn: "12345678",
        vol: "4",
        article_title: "The epidemiology of rat-based vector diseases",
        author: "Dr Testperson",
        pages: "212-59",
        citation: "Testperson, K. The epidemiology of rat-based vector diseases. J Malarial Stud. London: (4) 212-59.",
        pub_notes: "Cannot be retrieved in English",
      }
  end

  def test_email_success
    perform_enqueued_jobs do
      ServiceArticleRequestJob.perform_now(
        @support_email,
        @publication,
        patron: @patron,
        )
    end
    test_email = RequestMailer.deliveries.last
    assert_email test_email,
      subject: 'Alt-Media Service - Article Request',
      to: [@support_email]
  end

  # def test_failure_email
  #   perform_enqueued_jobs do
  #     raise "Error so that job fails"
  #     ServiceArticleRequestJob.perform_now(
  #       @support_email,
  #       @publication,
  #       patron: @patron,
  #       )
  #   end
  #   test_email = RequestMailer.deliveries.last
  #   assert_email test_email,
  #     subject: 'Alt-Media Service - Article Request',
  #     to: [@support_email]
  # end

end
