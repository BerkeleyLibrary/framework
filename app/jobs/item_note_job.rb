class ItemNoteJob < ApplicationJob
  # TODOs: MAYBE setup a different queue for this job
  queue_as :default

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

  def perform(env, id, note, num, email)
    # Find or create the item task
    task = Alma::ItemNoteTask.find_or_create_by(
      environment: env,
      set_id: id,
      note_text: note,
      note_num: num,
      email:
    ) do |new_task|
      new_task.job_id = job_id
    end

    unless task.completed?
      # If offset is zero we're just starting, so set some task level values
      # and send the "yay we're starting your job" email...
      if task['offset'] == 0
        set_info = Alma::ItemSet.fetch_set_info(env, id)
        task.itemset_name(set_info['name']) if set_info
        task.item_count(set_info['number_of_members']['value']) if set_info

        unless task.started_email_sent?
          send_email(email, start_message(task['set_name']))
          task.sent_email 'started'
        end
      end

      # Define an ItemSet object to handle the complicated stuff...
      set = Alma::ItemSet.new(env, id)

      # start updating those notes
      set.update_notes(task)
    end

    # If completed, then check if we've sent the email!
    # rubocop:disable Style/GuardClause
    if task.completed? && !task.completed_email_sent?
      send_email(email, complete_message(num, task['set_name']))
      task.sent_email 'completed'
    end
    # rubocop:enable Style/GuardClause
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

  private

  def send_email(email, msg)
    RequestMailer.item_notes_update_email(email, msg).deliver_now
  end

  def start_message(set_name)
    "We have begun to update your set: #{set_name}"
  end

  def complete_message(num, set_name)
    "We have finished updating internal note #{num} on all items in set #{set_name}."
  end
end
