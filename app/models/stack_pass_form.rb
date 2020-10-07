class StackPassForm < StackRequest
  validate :date_check

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

  def date_check
    date_entered = pass_date || nil
    max_date = Date.today + 7
    today = Date.today

    if date_entered
      errors.add(:pass_date, 'The date must not be in the past') if date_entered < today
      errors.add(:pass_date, 'The date must be within 7 days of today') if date_entered > max_date
    else
      errors.add(:pass_date, 'The date must not be blank and must be in the format mm/dd/yyyy')
    end
  end

end
