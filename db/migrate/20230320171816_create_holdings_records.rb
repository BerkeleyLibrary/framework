class CreateHoldingsRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :holdings_records do |t|
      t.references :holdings_task, null: false, foreign_key: true

      t.string :oclc_number, null: false

      t.string :ht_record_url
      t.string :ht_error
      t.boolean :ht_retrieved, null: false, default: false

      t.string :wc_symbols
      t.string :wc_error
      t.boolean :wc_retrieved, null: false, default: false

      t.timestamps
      t.index [:holdings_task_id, :oclc_number], unique: true
    end
  end
end
