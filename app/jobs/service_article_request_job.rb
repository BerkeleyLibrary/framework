require 'request_mailer'

class ServiceArticleRequestJob < ApplicationJob
  queue_as :default

  def perform(email, publication, patron:)
    patron = Patron::Record.new(**patron)
    send_patron_email(email, publication, patron)
  rescue
    send_failure_email(patron)
    raise # so rails will log it
  end

  private

  def send_patron_email(email, patron)
    RequestMailer.service_article_confirmation_email(email, publication, patron).deliver_now
  end

  def send_failure_email(patron)
    RequestMailer.service_article_failure_email(patron.id, patron.name).deliver_now
  end

end