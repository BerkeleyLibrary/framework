module Alma

  # Collection (array) of sets
  class ItemSet
    include ActiveModel::Model

    attr_accessor :env, :id, :name, :items

    def initialize(env, id)
      @env = env
      @id = id
      @name = ''
      @items = []
    end

    # We're going to create item objects and push them into
    # the items array attribute of the item_set object
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def fetch_items
      offset = 0
      count = 0

      # These sets can be ridiculously huge - for now set to max 100
      loop do
        members = AlmaServices::ItemSet.fetch_members(id, env, offset)
        bibs_regex = %r{^.*/bibs/(\d+)/holdings/(\d+)/items/(\d+)$}

        members['member'].each do |member|
          count += 1
          m = member['link'].match bibs_regex
          item = Alma::Item.find(env, m[1], m[2], m[3])
          items.push(item)
        end

        offset += 50
        break if count >= 200
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    class << self
      def fetch_set_array(env)
        fetch_item_sets env
      end

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
