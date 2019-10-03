require 'request_mailer'

class LibstaffEdevicesLoanJob < ApplicationJob
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
    @note ||= "#{today} Library Staff Electronic Devices eligible [litscript]"
  end

  private

  def send_patron_email(patron)
    RequestMailer.libdevice_confirmation_email(patron.email).deliver_now
  end

  def send_failure_email(patron, note)
    RequestMailer.libdevice_failure_email(patron.id, patron.name, note).deliver_now
  end
end
