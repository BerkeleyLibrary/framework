class DoemoffStudyRoomUseForm < Form
  # TODO(JS): There's got to be a better way to set all of the Patron::Type
  # items to ALLOWED_PATRON_TYPES
  ALLOWED_PATRON_TYPES = [
    Alma::Type::UNDERGRAD,
    Alma::Type::UNDERGRAD_SLE,
    Alma::Type::GRAD_STUDENT,
    Alma::Type::FACULTY,
    Alma::Type::MANAGER,
    Alma::Type::LIBRARY_STAFF,
    Alma::Type::STAFF,
    Alma::Type::POST_DOC,
    Alma::Type::VISITING_SCHOLAR
  ].freeze

  # Users must explicitly opt-in to each clause of the form.
  attr_accessor :borrow_check, :fines_check, :roomUse_check
  attr_accessor :display_name
  attr_accessor :patron

  delegate :email, to: :patron, prefix: true
  delegate :id, to: :patron, prefix: true
  delegate :type, to: :patron, prefix: true

  validates :borrow_check,
            :fines_check,
            :roomUse_check,
            inclusion: { in: %w[checked] }

  validates :display_name,
            presence: true

  validates :patron,
            patron: {
              types: ALLOWED_PATRON_TYPES
            },
            strict: true

  validates :patron_email,
            email: true,
            presence: true

  private

  def submit
    DoemoffStudyRoomUseJob.perform_later(patron_id)
  end
end
