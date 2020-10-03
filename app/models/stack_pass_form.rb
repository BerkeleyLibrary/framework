class StackPassForm < StackRequest
  validate :valid_dates

  def submit!
    RequestMailer.stack_pass_email(self).deliver_now
  end

  def approve!
    RequestMailer.stack_pass_approved(self).deliver_now
  end

  def deny!
    RequestMailer.stack_pass_denied(self).deliver_now
  end

  def approval_count
    StackPassForm.where('email = ? AND approvedeny = ? AND pass_date >= ?', email, true, start_school_year).count
  end

  def denial_count
    StackPassForm.where('email = ? AND approvedeny = ? AND pass_date >= ?', email, false, start_school_year).count
  end

  private

  def valid_dates
    if pass_date.present?
      errors.add(:pass_date, 'The Pass Date must not be in the past') if pass_date.past?
    else
      errors.add(:pass_date, 'The Pass Date must not be blank and must be in the format mm/dd/yyyy')
    end
  end

end
