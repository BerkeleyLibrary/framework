class CreateTindValidators < ActiveRecord::Migration[7.0]
  def change
    create_table :tind_validators do |t|

      t.timestamps
    end
  end
end
