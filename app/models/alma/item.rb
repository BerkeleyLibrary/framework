require 'json'

module Alma
  class Item
    include ActiveModel::Model

    attr_accessor :env, :mms_id, :holding_id, :item_pid, :item

    class << self
      def find(env, mms_id, holding_id, item_pid)
        raw_item = AlmaServices::ItemSet.fetch_item(env, mms_id, holding_id, item_pid)
        return unless raw_item

        Alma::Item.new env, mms_id, holding_id, item_pid, raw_item
      end
    end

    def initialize(env, mms_id, holding_id, item_pid, raw_item = nil)
      return unless raw_item

      @item = raw_item
      @env = env
      @mms_id = mms_id
      @holding_id = holding_id
      @item_pid = item_pid
    end

    def add_note(num, note_text)
      prepend_note(num, note_text)
      save
    end

    def to_json(*_args)
      item.to_json
    end

    private

    def prepend_note(num, note)
      # Get the existing note from this item
      existing_note = note(num)

      # Don't add if the note already exists
      return if existing_note.include? note

      # Add the pre-existing note (w/pipe) if it exists
      note += " | #{existing_note}" if existing_note.present?

      # Add it to the item's internal note field
      @item['item_data']["internal_note_#{num}"] = note
    end

    def note(num)
      item['item_data']["internal_note_#{num}"]
    end

    def save
      AlmaServices::ItemSet.save_item self
    end
  end
end
