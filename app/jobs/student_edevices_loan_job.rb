require 'request_mailer'

class StudentEdevicesLoanJob < ApplicationJob
  queue_as :default

  def perform(patron:)
    patron = Patron::Record.new(**patron)
    now = Time.now.strftime('%Y%m%d')
    note = "#{now} Student Electronic Devices eligible [litscript]"

    patron.add_note(note)
    send_patron_email(patron)
  rescue
    send_failure_email(patron, note)
    raise # so rails will log it
  end

  private

  def send_patron_email(patron)
    RequestMailer.student_edevices_confirmation_email(patron.email).deliver_now
  end

  def send_failure_email(patron, note)
    RequestMailer.student_edevices_failure_email(patron.id, patron.name, note).deliver_now
  end
end

