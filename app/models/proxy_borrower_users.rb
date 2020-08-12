# == Schema Information
#
# Table name: proxy_borrower_users
#
# lcasid :bigint   null: false
# name   :string   null: false
# role   :string   null: false
# email  :string

class ProxyBorrowerUsers < ActiveRecord::Base
  validates :lcasid,
            presence: true
  validates :name,
            presence: true
  validates :role,
            presence: true

  # Hardcoded admins - so if for some reason all of the
  # admins in the DB are deleted, we still have a way of
  # getting in and managing things!
  @hardcoded_admins = [
    '7165',    # Lisa Weber
    '1684944', # David Moles
    '1707532'  # Steve Sullivan
  ]

  def self.proxy_user_role(user_id)
    return 'Admin' if @hardcoded_admins.include?(user_id)

    user = ProxyBorrowerUsers.find_by(lcasid: user_id)

    return nil if user.blank?

    user.role
  end
end
