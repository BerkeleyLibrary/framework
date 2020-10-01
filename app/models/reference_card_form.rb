class ReferenceCardForm < StackRequest
  validate :valid_start_date
  validate :valid_end_date

  def submit!
    RequestMailer.reference_card_email(self).deliver_now
  end

  def approve!
    RequestMailer.reference_card_approved(self).deliver_now
  end

  def deny!
    RequestMailer.reference_card_denied(self).deliver_now
  end

  # Add up and return the total number of days this requester
  # has been approved for (for the current school year)
  def days_approved
    total_approved_days = 0
    approvals = ReferenceCardForm.where('email = ? AND approvedeny = ? AND pass_date_end >= ?', email, true, start_school_year)
    approvals.each do |approval|
      total_approved_days = + (approval.pass_date_end - approval.pass_date).to_i + 1
    end
    total_approved_days
  end

  private

  # I need to figure out the 'current school year' (July - June)
  # for the moment.... So if it's August, then July 1st of the current year
  # but if it's April, then I'd want July 1st of LAST year....
  def start_school_year
    today = Date.today
    mo = today.month
    yr = today.year
    yr -= 1 if mo < 7
    Date.new(yr, 7, 0o1)
  end

  def valid_start_date
    errors.add(:pass_date, 'The Start Date must not be blank and must be in the format mm/dd/yyyy') unless pass_date.present?
  end

  def valid_end_date
    errors.add(:pass_date_end, 'The End Date must not be blank and must be in the format mm/dd/yyyy') unless pass_date_end.present?
  end

end
