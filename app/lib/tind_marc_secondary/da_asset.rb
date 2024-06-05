require 'find'
require_relative 'tind_verification'

module TindMarcSecondary

  class DaAsset
    def initialize(da_batch_path, verify_tind, collection_name)
      @verify_tind = verify_tind
      @da_batch_path = da_batch_path
      @collection_name = collection_name
    end

    def assets_hash
      assets = batch_assets
      assets_verified(assets)
    rescue StandardError => e
      Rails.logger.error "Inventory not populated: #{e}"
    end

    private

    def batch_assets
      folder_names = Dir.children(@da_batch_path).select { |f| File.directory?(File.join(@da_batch_path, f)) }
      folder_names.map do |folder_name|
        { mmsid: folder_name.split('_')[0].strip, folder_name: }
      end
    end

    # verifying from TIND
    def assets_verified(assets)
      verification = TindVerification.new(@collection_name)
      insert_assets = []
      append_assets = []
      assets.each do |asset|
        f_035 = verification.f_035(asset[:mmsid])
        f_035 ? append(asset, f_035, append_assets) : insert_assets.push(asset)
      end

      { insert: insert_assets, append: append_assets }
    end

    def append(asset, f_035, assets)
      asset[:f_035_from_tind] = f_035
      assets.push(asset)
    end

  end
end
