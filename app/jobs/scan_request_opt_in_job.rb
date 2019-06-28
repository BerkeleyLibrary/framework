require 'request_mailer'

class ScanRequestOptInJob < ApplicationJob
  queue_as :default

  def perform(patron_id)
    patron = Patron::Record.find(patron_id)
    patron.add_note(note)
    send_patron_email(patron)
    send_baker_email(patron)
  rescue
    send_failure_email(patron, note)
    raise # so rails will log it
  end

  def note
    @note ||= "#{today} library book scan eligible [litscript]"
  end

private

  def send_patron_email(patron)
    RequestMailer.confirmation_email(patron.email).deliver_now
  end

  def send_baker_email(patron)
    RequestMailer.confirmation_email_baker(patron.email, patron.id).deliver_now
  end

  def send_failure_email(patron, note)
    RequestMailer.failure_email(patron.id, patron.name, note).deliver_now
  end
end
