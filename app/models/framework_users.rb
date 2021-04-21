# == Schema Information
#
# Table name: framework_users
#
# lcasid :bigint   null: false
# name   :string   null: false
# role   :string   null: false   <--- NOT USED
# email  :string                 <--- NOT USED

# Model for any framework form that requires priviledged admin users

# TODO: rename to FrameworkUser (singular)
class FrameworkUsers < ActiveRecord::Base
  has_many :assignments
  has_many :roles, through: :assignments

  validates :lcasid,
            presence: true
  validates :name,
            presence: true
  validates :role,
            presence: true

  class << self
    # Hardcoded admins - so if for some reason all of the
    # admins in the DB are deleted, we still have a way of
    # getting in and managing things!
    def hardcoded_admin_uids
      [
        '7165',    # Lisa Weber
        '1684944', # David Moles
        '1707532'  # Steve Sullivan
      ]
    end

    # check if a user exists and has a role
    def role?(user_id, role)
      return true if hardcoded_admin_uids.include?(user_id)

      role.assignments.exists?(framework_users_id: user_id)
    end
  end

end
