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
  has_many :assignments, dependent: :destroy
  has_many :roles, through: :assignments

  validates :lcasid,
            presence: true
  validates :name,
            presence: true
  validates :role,
            presence: true

end
