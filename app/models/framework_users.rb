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
  end

  def hardcoded_admin_uids
    FrameworkUsers.hardcoded_admin_uids
  end

  # check if a user exists and has a role
  def self.role?(user_id, role)
    # Check if user is hardcoded (global) admin:
    return true if hardcoded_admin_uids.include?(user_id)

    # If not, check if a user exists:
    user = FrameworkUsers.find_by(lcasid: user_id)
    return nil if user.blank?

    # She/he does....let's check if they have the proper assignment:
    assignments = user.assignments.map { |a| a.role.role } || []
    assignments.include?(role)
  end

  # check if the current user is assigned a role
  def assigned?(role)
    assignments = self.assignments.map { |a| a.role.role } || []
    assignments.include?(role)
  end

  # Return the list of all users with a specific role:
  def self.users_with_role(role)
    users = []

    FrameworkUsers.all.each do |user|
      users.push(user) if user.assigned?(role)
    end

    users
  end
end
