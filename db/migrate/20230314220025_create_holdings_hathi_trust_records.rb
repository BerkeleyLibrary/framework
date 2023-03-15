class CreateHoldingsHathiTrustRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :holdings_hathi_trust_records do |t|
      t.references :holdings_task, null: false, foreign_key: true
      t.string :oclc_number, null: false
      t.string :ht_record_url
      t.string :ht_error
      t.boolean :retrieved, null: false, default: false

      t.timestamps

      t.index [:holdings_task_id, :oclc_number], unique: true, name: 'index_holdings_ht_on_task_id_and_oclc_number'
    end
  end
end
