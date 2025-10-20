class AddProcessedByIdToStackRequests < ActiveRecord::Migration[7.0]
  def up
    add_column :stack_requests, :processed_by_id, :integer
    add_foreign_key :stack_requests, :framework_users, column: :processed_by_id

    StackRequest.find_each do |request|
      request.processed_by_id = FrameworkUsers.find_by_name(request.processed_by)
    end
  end

  def down
    StackRequest.where(processed_by: nil).find_each do |request|
      request.processed_by = FrameworkUsers.name_for_lcasid(request.processed_by_id)
    end
    delete_column :stack_requests, :processed_by_id, :integer
  end
end
