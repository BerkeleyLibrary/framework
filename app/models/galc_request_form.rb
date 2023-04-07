class GalcRequestForm < Form
  ALLOWED_PATRON_TYPES = [
    Alma::Type::UNDERGRAD,
    Alma::Type::UNDERGRAD_SLE,
    Alma::Type::GRAD_STUDENT,
    Alma::Type::FACULTY,
    Alma::Type::MANAGER,
    Alma::Type::LIBRARY_STAFF,
    Alma::Type::STAFF
  ].freeze

  attr_accessor :borrow_check
  attr_accessor :fine_check
  attr_accessor :patron

  attr_writer :patron_email
  attr_writer :support_email

  delegate :id, to: :patron, prefix: true
  delegate :name, to: :patron, prefix: true

  validates :patron,
            patron: {
              types: ALLOWED_PATRON_TYPES
            },
            strict: true

  validates :patron_email,
            email: true

  validates :patron_name,
            presence: true

  # Users must explicitly opt-in to each clause of the form.
  validates :borrow_check, :fine_check,
            inclusion: { in: %w[checked] }

  def support_email
    @support_email ||= 'eref-library@berkeley.edu'
  end

  # Cannot use the delegate method because that is for read-only attributes
  def patron_email
    @patron_email ||= @patron.email if @patron
  end

  private

  def submit
    GalcRequestJob.perform_later(patron_id)
  end
end
