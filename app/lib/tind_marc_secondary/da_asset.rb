require 'find'

module TindMarcSecondary

  class DaAsset
    def initialize(da_batch_path, verify_tind)
      @verify_tind = verify_tind
      @da_batch_path = da_batch_path
    end

    def map
      assets = batch_assets
      @verify_tind ? assets_verified(assets) : { insert: assets }
    rescue StandardError => e
      Rails.logger.error "Inventory not populated: #{e}"
    end

    private

    def batch_assets
      folder_names = Dir.children(@da_batch_path).select { |f| File.directory?(File.join(@da_batch_path, f)) }
      folder_names.map do |folder_name|
        {
          mmsid: folder_name.split('_')[0].strip,
          folder_name:
        }
      end
    end

    # verifying from TIND
    def assets_verified(assets)
      { insert: assets, append: [] }
    end

  end
end
