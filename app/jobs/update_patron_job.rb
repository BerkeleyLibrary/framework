require 'net/ssh'
require 'request_mailer'
require 'shellwords'

class UpdatePatronJob < ApplicationJob
  queue_as :default

  def perform(employee_id:, email:, firstname:, lastname:)
    #internal note that will be added to patron record in Millennium
    now = Time.now.strftime("%Y%m%d")
    note = "#{now} library book scan eligible [litscript]"

    # Connection info, including credentials, sourced from rails config
    host = Rails.application.config.expect_url.host
    user = Rails.application.config.expect_url.user
    opts = { non_interactive: true }
    cmd  = [
      Rails.application.config.expect_url.path,
      note,
      employee_id,
    ].shelljoin

    res = Net::SSH.start(host, user, opts) { |ssh| ssh.exec!(cmd) }

    if res.match('Finished Successfully')
      RequestMailer.confirmation_email(email).deliver_now
    else
      #expect script failed send error to prntscan list
      RequestMailer.failure_email(
        employee_id,
        firstname,
        lastname,
        note
      ).deliver_now
    end
  end
end
