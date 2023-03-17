class AddForeignKeyConstraintToAssignmentsForRoleId < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :assignments, :roles
  end
end
