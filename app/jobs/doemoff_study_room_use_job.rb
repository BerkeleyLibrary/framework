require 'request_mailer'

class DoemoffStudyRoomUseJob < ApplicationJob
  queue_as :default

  def perform(patron:)
    
  
  end

  private

  def send_patron_email(patron)
    
  end

  def send_failure_email(patron, note)
    
  end
end