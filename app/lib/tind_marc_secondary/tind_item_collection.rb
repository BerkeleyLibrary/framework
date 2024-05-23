module TindMarcSecondary
  class TindItemCollection
    attr_reader :items

    Item = Struct.new(:folder_name, :tag_035, :file_desc_hash) do
      def display
        "Folder_name: #{folder_name}, Tag_035: #{tag_035}, Fiel_Des_Hash: $#{file_desc_hash}"
      end
    end

    def initialize
      @items = []
    end

    def add_item(folder_name, tag_035, file_desc_hash)
      item = Item.new(folder_name, tag_035, file_desc_hash)
      @items << item
    end

    def display_items
      @items.each do |item|
        Rails.logger.info(item.display)
      end
    end
  end
end
