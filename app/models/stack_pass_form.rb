class StackPassForm < StackRequest

  def submit!
    RequestMailer.stack_pass_email(self).deliver_now
  end

  def approve!
    RequestMailer.stack_pass_approved(self).deliver_now
  end

  def deny!
    RequestMailer.stack_pass_denied(self).deliver_now
  end

  # Need to be able to get counts for a requester - they're capped for a specific number of
  # requests per year (resets on July 1st I believe)

  # Need to move these into sub models (stack_pass and ref_card)
  def approval_count
    StackPassForm.where(email: email, approvedeny: true).count
  end

  def denial_count
    StackPassForm.where(email: email, approvedeny: false).count
  end

end
