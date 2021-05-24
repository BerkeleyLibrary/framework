class CreateLendingItems < ActiveRecord::Migration[6.0]
  def change
    create_table :lending_items do |t|
      t.string :barcode
      t.string :filename
      t.string :title
      t.string :author
      t.string :millennium_id
      t.string :alma_id
      t.string :string
      t.int :copies

      t.timestamps
    end
  end
end
