require 'request_mailer'

class GalcRequestJob < ApplicationJob
  queue_as :default

  def perform(patron_id)
    patron = Patron::Record.find(patron_id)
    patron.add_note(note)
    send_patron_email(patron)
  rescue StandardError
    send_failure_email(patron, note)
    raise
  end

  def note
    @note ||= "#{today} GALC eligible [litscript]"
  end

  private

  def send_patron_email(patron)
    RequestMailer.galc_confirmation_email(patron.email).deliver_now
  end

  def send_failure_email(patron, note)
    RequestMailer.galc_failure_email(patron.id, patron.name, note).deliver_now
  end
end
