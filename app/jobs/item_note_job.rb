class ItemNoteJob < ApplicationJob
  queue_as :default

  def perform(env, id, note, num, email)
    set = Alma::ItemSet.new(env, id)
    set.fetch_items

    msg = "Starting to update #{set.items.count} in your set. You should get an email when this job is complete."

    # Send an initial email to notify user we've started
    RequestMailer.item_notes_update_email(email, msg).deliver_now

    set.items.each_with_index do |i, _idx|
      i.prepend_note num, note
      i.save
    end

    msg = "Job complete. We have added the note to all #{set.items.count} items."

    # Send an email to the user to notify that we've completed the job
    RequestMailer.item_notes_update_email(email, msg).deliver_now
  end
end
