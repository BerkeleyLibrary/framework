class RenameRlfToSlfOnLocationRequests < ActiveRecord::Migration[7.0]
  def change
    rename_column :location_requests, :rlf, :slf
  end
end
