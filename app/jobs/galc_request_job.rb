class GalcRequestJob < PatronNoteJobBase
  NOTE_TXT = 'GALC eligible'.freeze
  MAILER_PREFIX = 'galc'.freeze

  def initialize(*)
    super(*, mailer_prefix: MAILER_PREFIX, note_txt: NOTE_TXT)
  end
end
