class AddImmediateToHoldingsRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :holdings_requests, :immediate, :boolean, null: false, default: false
  end
end
