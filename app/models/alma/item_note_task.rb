# this essentially just tracks the job in the DB
module Alma
  class ItemNoteTask < ActiveRecord::Base
    # TODO: add some validations...

    validates :job_id, presence: true
    validates :environment, presence: true
    validates :set_id, presence: true
    validates :note_text, presence: true
    validates :note_num, presence: true
    validates :email, presence: true, email: true

    def complete
      update(completed: true)
      update(job_completed_at: DateTime.now)
    end

    def completed_email_sent?
      completed_email_sent
    end

    def started_email_sent?
      completed_email_sent
    end

    def completed?
      completed
    end

    def sent_email(type)
      update(started_email_sent: true) if type == 'started'
      update(completed_email_sent: true) if type == 'completed'
    end

    def item_count(count)
      update(item_count: count)
    end

    def increment_offset
      update(offset: offset + 1)
    end

    def itemset_name(name)
      update(set_name: name)
    end

  end
end
