class HoldingsWorldCatRecord < ActiveRecord::Base
  belongs_to :holdings_task

  validates :oclc_number, presence: true
end
