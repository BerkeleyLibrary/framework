class ReferenceCardForm < StackRequest
  validate :date_check

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

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def date_check
    date_start = pass_date || nil
    date_end = pass_date_end || nil

    if date_start && date_end
      num_req = + (date_end - date_start).to_i + 1
      errors.add(:pass_date, 'must not be in the past') if date_start < Date.today
      errors.add(:pass_date_end, 'must not precede access start date') if date_start > date_end
      errors.add(:pass_date_end, 'cannot be more than 3 months from the start date') if num_req > 91
    else
      errors.add(:pass_date, 'must not be blank and must be in the format mm/dd/yyyy') unless date_start
      errors.add(:pass_date_end, 'must not be blank and must be in the format mm/dd/yyyy') unless date_end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

end
