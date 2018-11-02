require 'request_mailer'

class ScanRequestOptOutJob < ApplicationJob
  queue_as :default

  def perform(patron:)
    patron = Patron::Record.new(**patron)
    RequestMailer.opt_out_staff(patron.id, patron.name).deliver_now
    RequestMailer.opt_out_faculty(patron.email).deliver_now
  end
end
