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

    def note(num)
      item['item_data']["internal_note_#{num}"]
    end

    def prepend_note(num, note)
      existing_note = note(num)
      note += " | #{existing_note}" if existing_note.present?
      @item['item_data']["internal_note_#{num}"] = note
    end

    def save
      AlmaServices::ItemSet.save_item self
    end

    def to_json(*_args)
      item.to_json
    end

  end
end
