# Base class for both Stack Pass and Reference Card
# Both SP and RC offer access to the Gardner main stacks
# SP is for a single day; RC is for multiple days
class StackRequest < ActiveRecord::Base

  validates :name,
            presence: true

  validates :email,
            presence: true,
            email: true

end
