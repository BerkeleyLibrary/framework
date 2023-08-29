class RemoveUniqueConstraintFromLocationRecords < ActiveRecord::Migration[7.0]
  def change
    remove_index :location_records, name: 'index_location_records_on_location_request_id_and_oclc_number'
  end
end
