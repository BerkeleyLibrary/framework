class RenameHoldingsTasksToHoldingsRequests < ActiveRecord::Migration[7.0]
  def change
    rename_table :holdings_tasks, :holdings_requests
    rename_column :holdings_records, :holdings_task_id, :holdings_request_id
  end
end
