require 'find'
require_relative 'tind_item_collection'

module TindMarcSecondary

  class DaBatch
    def initialize(config, verify_tind)
      @verify_tind = verify_tind
      @config = config
    end

    def item_collection
      items = items_from_da_folder
      @verify_tind ? items_verified(items) : { insert: items }
    rescue StandardError => e
      Rails.logger.error "Inventory not populated: #{e}"
    end

    private

    def items_from_da_folder
      folder_names = Dir.children(@config.da_batch_path).select { |f| File.directory?(File.join(@config.da_batch_path, f)) }
      folder_names.map do |folder_name|
        {
          mmsid: folder_name.split('_')[0].strip,
          folder_name:
        }
      end
    end

    def items_verified(items)
      { insert: items, append: [] }
    end

  end
end
