class LibstaffEdevicesLoanForm < Form

  ALLOWED_PATRON_AFFILIATIONS = [
    Patron::Affiliation::UC_BERKELEY,
    #Patron::Affiliation::COMMUNITY_COLLEGE, #including this option for when testing
  ]

  ALLOWED_PATRON_TYPES = [
    Patron::Type::LIBRARY_STAFF,
    #Patron::Type::VISITING_SCHOLAR, #including this option for when testing
  ]

  attr_accessor(
    :borrow_check,
    :lending_check,
    :fines_check,
    :edevices_check,
    :full_name,
    :staff_id_number,
    :today_date,
    :staff_email,
  )

  # Patron making the request
  # @return [Patron::Record]
  attr_accessor :patron
  validates :patron, presence: true

  # Display name of the patron making the request
  # @return [String]
  attr_accessor :patron_name
  validates :patron_name, presence: true

  # @!attribute [r] patron_type
  #   @return [Patron::Type]
  delegate :type, to: :patron, prefix: true
  validates :patron_type, inclusion: { in: ALLOWED_PATRON_TYPES }

  # @!attribute [r] patron_affiliation
  #   @return [Patron::Affiliation]
  delegate :affiliation, to: :patron, prefix: true
  validates :patron_affiliation, inclusion: { in: ALLOWED_PATRON_AFFILIATIONS }

  # @!attribute [r] patron_blocks
  #   @return [String, nil]
  delegate :blocks, to: :patron, prefix: true
  validates :patron_blocks, absence: true

  def blocked?
    not valid? and errors.include?(:patron_blocks)
  end

  def allowed?
    valid? or not errors.include?(:patron_type)
  end

  def all_checked?(params)
    params['libstaff_edevices_loan_form']['borrow_check'] == "checked" && params['libstaff_edevices_loan_form']['lending_check'] == "checked" && params['libstaff_edevices_loan_form']['fines_check'] == "checked" && params['libstaff_edevices_loan_form']['edevices_check'] == "checked"
  end

  def process(params)
    all_checked! if all_checked?(params)
  end

  def all_checked!
    LibstaffEdevicesLoanJob.perform_later(
      patron: {
        email: patron.email,
        id: patron.id,
        name: patron.name,
      },
    )
  end
end


