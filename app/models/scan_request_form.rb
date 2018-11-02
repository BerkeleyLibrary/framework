# Allow qualified academic patrons to request scans of documents
#
# This is commonly referred to as the "AltMedia" form.
class ScanRequestForm < Form
  attr_accessor(
    :opt_in,
    :patron_affiliation,
    :patron_blocks,
    :patron_email,
    :patron_employee_id,
    :patron_name,
    :patron_type,
  )

  validates :opt_in,
    inclusion: { in: %w(yes no) }

  validates :patron_affiliation,
    inclusion: {
      in: [
        Patron::Affiliation::UC_BERKELEY,
      ],
    }

  validates :patron_blocks,
    absence: true

  validates :patron_email,
    presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :patron_name,
    presence: true

  validates :patron_type,
    inclusion: {
      in: [
        Patron::Type::FACULTY,
        Patron::Type::VISITING_SCHOLAR,
        # Temporary?
        Patron::Type::MANAGER,
        Patron::Type::LIBRARY_STAFF,
        Patron::Type::STAFF,
      ],
    }

  def allowed?
    valid? or not errors.include?(:patron_type)
  end

  def blocked?
    not valid? and errors.include?(:patron_blocks)
  end

  def opted_in?
    opt_in == 'yes'
  end

  private

  def submit
    opted_in? ? opt_in! : opt_out!
  end

  def opt_in!
    ScanRequestOptInJob.perform_later(
      patron: {
        email: patron_email,
        id: patron_employee_id,
        name: patron_name,
      },
    )
  end

  def opt_out!
    ScanRequestOptOutJob.perform_later(
      patron: {
        email: patron_email,
        id: patron_employee_id,
        name: patron_name,
      },
    )
  end

end
