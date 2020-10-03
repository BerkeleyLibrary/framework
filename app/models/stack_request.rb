# Base class for both Stack Pass and Reference Card
# Both SP and RC offer access to the Gardner main stacks
# SP is for a single day; RC is for multiple days
class StackRequest < ActiveRecord::Base

  validates :name,
            presence: true

  validates :email,
            presence: true,
            email: true

  private

  # I need to figure out the 'current school year' (July - June)
  # for the moment.... So if it's August, then July 1st of the current year
  # but if it's April, then I'd want July 1st of LAST year....
  def start_school_year
    today = Date.today
    mo = today.month
    yr = today.year
    yr -= 1 if mo < 7
    Date.new(yr, 7, 1)
  end
end
