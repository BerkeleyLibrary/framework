require 'find'
require_relative 'tind_verification'

module TindMarcSecondary

  class DaAsset
    def initialize(da_batch_path, verify_tind)
      @verify_tind = verify_tind
      @da_batch_path = da_batch_path
    end

    def assets_hash
      assets = batch_assets
      puts "mine asset"
      puts assets
      a = assets_verified(assets)
      puts "mine asset"
      puts a
      a
      # @verify_tind == 1 ? assets_verified(assets) : { insert: assets }
    rescue StandardError => e
      Rails.logger.error "Inventory not populated: #{e}"
    end

    private

    # mmsid in a folder name may be different from mmsid in a csv file: preparing for external csv files
    # def batch_assets
    #   folder_names = Dir.children(@da_batch_path).select { |f| File.directory?(File.join(@da_batch_path, f)) }
    #   folder_names.map do |folder_name|
    #     {
    #       mmsid: folder_name.split('_')[0].strip,
    #       folder_name:
    #     }
    #   end
    # end

    def batch_assets
      folder_names = Dir.children(@da_batch_path).select { |f| File.directory?(File.join(@da_batch_path, f)) }
      folder_names.map do |folder_name|
        { mmsid: folder_name.split('_')[0].strip, folder_name: }
      end
    end

    # verifying from TIND
    def assets_verified(assets)
      collection_name = 'Map Collections'
      verification = TindVerification.new(collection_name)
      insert_assets = []
      append_assets = []
      assets.each do |asset|
        f_035 = verification.f_035(asset[:mmsid])
        puts "he is here"
        puts f_035
        f_035 ? append(asset, f_035, append_assets) : insert_assets.push(asset) 
      end
      
      puts "a is here"
      puts insert_assets
      puts append_assets
      v = { insert: insert_assets, append: append_assets }
      puts "v is here"
      puts v
      v
    end

    def append(asset, f_035, assets)
      asset[:f_035_from_tind] = f_035
      assets.push(asset)
    end

  end
end
