module Alma

  # Collection (array) of sets
  class ItemSet
    NUM_RECS = 10
    BIBS_REGEX = %r{^.*/bibs/(\d+)/holdings/(\d+)/items/(\d+)$}

    include ActiveModel::Model

    attr_accessor :env, :id

    def initialize(env, id)
      @env = env
      @id = id
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def update_notes(task)
      loop do
        # fetch_members will fetch 100 recs at a time...
        members = AlmaServices::ItemSet.fetch_members(id, env, task['offset'])

        # cycle through this batch of 100 members
        members['member'].each_with_index do |member, _idx|
          # Extract the link:
          m = member['link'].match BIBS_REGEX

          # Fetch the actual item
          item = Alma::Item.find(env, m[1], m[2], m[3])

          # Update && Save the Note
          item.add_note(task['note_num'], task['note_text'])

          # Add one to the offset
          task.increment_offset
        end

        task.complete if task['offset'] >= members['total_record_count']

        break if task.completed?
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    class << self

      # This uses fetch_item_sets below to fetch the collection of
      # sets of items from Alma and then return them to the form
      # as an array so the form can display a drop down of sets
      # the user can update.
      def fetch_set_array(env)
        fetch_item_sets env
      end

      # This fetches the general info for the set (name, #members)
      def fetch_set_info(env, id)
        AlmaServices::ItemSet.fetch_set(env, id)
      end

      # Initiate the job (jobs>item_note_job.rb)
      def prepend_note_to_set(env, id, note, num, email)
        ItemNoteJob.perform_later(env, id, note, num, email)
      end

      private

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def fetch_item_sets(source)
        # We can only fetch 100 item sets at a time so we
        # have to loop through the API to get all of them
        sets = []
        offset = 0

        loop do
          results = AlmaServices::ItemSet.fetch_sets(source, offset)
          results['set'].each do |set|
            # Ignore private sets!
            next if set['private']['value'] == 'true'

            sets.push([set['name'], set['id']])
          end
          offset += 100
          break if offset >= results['total_record_count']
        end

        sets.sort! { |a, b| a[0].downcase <=> b[0].downcase }

        sets
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    end

  end
end
