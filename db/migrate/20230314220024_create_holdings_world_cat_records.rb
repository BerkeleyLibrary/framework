class CreateHoldingsWorldCatRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :holdings_world_cat_records do |t|
      t.references :holdings_task, null: false, foreign_key: true
      t.string :oclc_number, null: false
      t.string :wc_symbols
      t.string :wc_error
      t.boolean :retrieved, null: false, default: false

      t.timestamps

      t.index [:holdings_task_id, :oclc_number], unique: true, name: 'index_holdings_wc_on_task_id_and_oclc_number'
    end
  end
end
