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
  validates :research_last, presence: { message: :missing }
  validates :research_first, presence: { message: :missing }
  validate :date_limit

  def submit!
    RequestMailer.proxy_borrower_request_email(self).deliver_now
    RequestMailer.proxy_borrower_alert_email(self).deliver_now
  end

  def full_name
    full_name = "#{research_last}, #{research_first} #{research_middle}"
    full_name.gsub(/\s+$/, '')
  end

  def self.to_csv
    attributes = %w[faculty_name department student_name dsp_rep proxy_name user_email date_term date_requested]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.find_each do |request|
        csv << attributes.map { |attr| request.send(attr) }
      end
    end
  end

  # Determine the maximum term for a proxy borrower request.
  # @return The last valid date for a request if it is submitted now.
  def self.max_term
    today = Date.current

    # If month is Jan - March, then max date is June 30th of the current year
    # else, if month is April - December, max date is June 30th of the following year
    yr = today.year
    yr += 1 if today.month >= 4

    Date.new(yr, 6, 30)
  end

  private

  # For the export we want am/pm, not military time:
  def date_requested
    created_at.in_time_zone('Pacific Time (US & Canada)').strftime('%D %r %Z')
  end

  # Export also wants the proxy name in one field (first last):
  def proxy_name
    proxy_name = "#{research_first} #{research_middle} #{research_last}"
    proxy_name.gsub(/\s+/, ' ')
  end

  def date_limit
    max = self.class.max_term
    return errors.add(:date_term, :missing) if date_term.blank?
    return errors.add(:date_term, :expired) if date_term < Date.current
    return errors.add(:date_term, :too_long, max_term: max.strftime('%B %e, %Y')) if date_term > max
  end
end
