require 'csv'

# == Schema Information
#
# Table name:  proxy_borrower_requests
# id               :bigint       not null, primary key
# faculty_name     :string       not null
# department       :string
# faculty_id       :string
# student_name     :string
# student_dsp      :string
# dsp_rep          :string
# research_last    :string       not null
# research_first   :string       not null
# research_middle  :string
# date_term        :date
# renewal          :integer      default(0)
# status           :integer      default(0)
# created_at       :datetime     not null
# updated_at       :datetime     not null
# user_email       :string
#

class ProxyBorrowerRequests < ActiveRecord::Base
  validates :research_last, presence: { message: 'Last name of proxy must not be blank' }
  validates :research_first, presence: { message: 'First name of proxy must not be blank' }
  validate :date_limit

  def submit!
    RequestMailer.proxy_borrower_request_email(self).deliver_now
    RequestMailer.proxy_borrower_alert_email(self).deliver_now
  end

  def full_name
    "#{research_last}, #{research_first}"
  end

  def self.to_csv
    attributes = %w[faculty_name department student_name dsp_rep proxy_name user_email date_term date_requested]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |request|
        csv << attributes.map { |attr| request.send(attr) }
      end
    end
  end

  private

  # For the export we want am/pm, not military time:
  def date_requested
    created_at.in_time_zone('Pacific Time (US & Canada)').strftime('%D %r %Z')
  end

  # Export also wants the proxy name in one field (first last):
  def proxy_name
    "#{research_first} #{research_last}"
  end

  def date_limit
    if date_term.present?
      if date_term.past?
        errors.add(:date_term, 'The Proxy Term must not be in the past')
      elsif date_term > max_term
        errors.add(:date_term, "The term of the Proxy Card must not be greater than #{max_term.strftime('%B %e, %Y')}")
      end
    else
      errors.add(:date_term, 'Term of proxy card must not be blank and must be in the format mm/dd/yyyy')
    end
  end

  def max_term
    today = Date.today
    mo = today.month
    yr = today.year

    # If month is Jan - March, then max date is June 30th of the current year
    # else, if month is April - December, max date is June 30th of the following year
    yr += 1 if mo >= 4

    Date.new(yr, 6, 30)
  end

end
