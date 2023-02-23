class CreateItemNoteTask < ActiveRecord::Migration[7.0]
  def change
    create_table :item_note_tasks do |t|
      # The GoodJob @job_id - not sure this will be used
      t.string :job_id, null: false

      # Once we've updated all of the items mark this task complete
      t.boolean :completed, default: false

      # Lets track if we've sent some of these emails so we don't spam folks!
      t.boolean :started_email_sent, default: false
      t.boolean :completed_email_sent, default: false


      # This feature can update either production or sandbox Alma
      t.string :environment, null: false

      # The set id...need this to get the members
      # we use the members to get the items
      t.string :set_id, null: false

      # Text we're appending
      t.string :note_text, null: false

      # Internal note we're updating: 1, 2 or 3
      t.integer :note_num, null: false

      # We send notifications to the user
      t.string :email, null: false
      
      # Use an offset to paginate through the members of the set via the API
      t.integer :offset, default: 0

      t.integer :item_count
      
      # Cuz why not?
      t.datetime :job_completed
      t.timestamps
    end
  end
end
