class Role < ActiveRecord::Base
  has_many :assignments
  has_many :framework_users, through: :assignments
end
