class PatronNoteJobBase < ApplicationJob
  queue_as :default

  # TODO: move job -> mailer lookup to RequestMailer
  attr_reader :mailer_prefix
  attr_reader :note_txt

  def initialize(*arguments, mailer_prefix:, note_txt:)
    @mailer_prefix = mailer_prefix
    @note_txt = note_txt
    super(*arguments)
  end

  def perform(patron_id)
    patron = Patron::Record.find(patron_id)
    patron.add_note(note)
    send_patron_email(patron)
  rescue StandardError
    send_failure_email(patron, note)
    raise
  end

  def note
    @note ||= "#{today} #{note_txt} [litscript]"
  end

  private

  def send_patron_email(patron)
    confirmation_email(patron).deliver_now
  end

  def send_failure_email(patron, note)
    failure_email(patron, note).deliver_now
  end

  def confirmation_email(patron)
    RequestMailer.send("#{mailer_prefix}_confirmation_email", patron.email)
  end

  def failure_email(patron, note)
    RequestMailer.send("#{mailer_prefix}_failure_email", patron.id, patron.name, note)
  end
end
