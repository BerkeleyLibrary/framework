class CreateHoldingsTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :holdings_tasks do |t|
      t.string :email, null: false
      t.string :filename, null: false
      t.boolean :rlf, default: false, null: false
      t.boolean :uc, default: false, null: false
      t.boolean :hathi, default: false, null: false

      t.timestamps
    end
  end
end
