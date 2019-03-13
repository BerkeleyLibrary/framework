require 'request_mailer'

class ServiceArticleRequestJob < ApplicationJob
  queue_as :default

  def perform(email, publication, patron:)
    patron = Patron::Record.new(**patron)
    send_patron_email(email, publication, patron)
  end

  private

  def send_patron_email(email, publication, patron)
    RequestMailer.service_article_confirmation_email(email, publication, patron).deliver_now
  end

  #In the case of something going wrong, send the fail email with the patron id and name to the support email address
  def handle_error(e)
    RequestMailer.service_article_failure_email(self.arguments[2][:patron][:id], self.arguments[2][:patron][:name]).deliver_now
  end

end