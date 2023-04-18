class AddScheduledAtToHoldingsRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :holdings_requests, :scheduled_at, :datetime
  end
end
