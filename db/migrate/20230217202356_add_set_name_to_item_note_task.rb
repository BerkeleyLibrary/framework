class AddSetNameToItemNoteTask < ActiveRecord::Migration[7.0]
  def change
        # Need this for the emails we generate
        add_column :item_note_tasks, :set_name, :string

        # While I'm at it, "job_completed" is a timestamp
        # not a bool, change name to reflect that:
        rename_column :item_note_tasks, :job_completed, :job_completed_at
  end
end
