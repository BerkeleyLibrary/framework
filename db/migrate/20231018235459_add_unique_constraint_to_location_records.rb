# AP-214
# I know I know... I just removed the constraint in the last migration.
# I thought removing the constraint would allow duplicate OCLC numbers
# to be updated in the spreadsheet. Turns out that the issue was in the
# BerkeleyLibrary Locations GEM.... bad Steve
class AddUniqueConstraintToLocationRecords < ActiveRecord::Migration[7.0]
  def change
    add_index :location_records, [:location_request_id, :oclc_number], unique: true
  end
end