class StackPassForm < ActiveRecord::Base

  validates :name,
            presence: true

  validates :email,
            presence: true,
            email: true

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

  def approval_count
    StackPassForm.where(email: email, approved: true).count
  end

  def denial_count
    StackPassForm.where(email: email, approved: false).count
  end

end
