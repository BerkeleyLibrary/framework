require 'find'
require_relative 'tind_verification'

module TindMarcSecondary

  class DaAsset
    def initialize(da_batch_path, verify_tind, send_mmsid_tind_info)
      @verify_tind = verify_tind
      @da_batch_path = da_batch_path
      @send_mmsid_tind_info = send_mmsid_tind_info
    end

    # def assets_hash
    #   assets = batch_assets
    #   prepare_hash(assets)
    # rescue StandardError => e
    #   Rails.logger.error "Inventory not populated: #{e}"
    #   { insert: [], append: [], messages: [e.message] }
    # end

    def assets_hash
      assets = batch_assets
      return prepare_mmsid_tind_information(assets) if @send_mmsid_tind_info

      prepare_hash(assets)
    rescue StandardError => e
      Rails.logger.error "Inventory not populated: #{e}"
      { insert: [], append: [], messages: [e.message] }
    end

    private

    def batch_assets
      folder_names = Dir.children(@da_batch_path).select { |f| File.directory?(File.join(@da_batch_path, f)) }
      folder_names.map do |folder_name|
        { mmsid: folder_name.split('_')[0].strip, folder_name: }
      end
    end

    def prepare_hash(assets)
      return { insert: assets, append: [] } unless @verify_tind

      prepare_verify_tind(assets)
    end

    def prepare_verify_tind(assets)
      verification = TindVerification.new
      insert_assets = []
      append_assets = []
      assets.each do |asset|
        f_035 = verification.f_035(asset[:mmsid])
        f_035 ? append(asset, f_035, append_assets) : insert_assets.push(asset)
      end

      { insert: insert_assets, append: append_assets }
    end

    def prepare_mmsid_tind_information(assets)
      verification = TindVerification.new
      tind_info = []
      assets.each do |asset|
        tind_record_ids = verification.record_ids(asset[:mmsid])
        tind_ids = tind_record_ids.empty? ? 'No TIND record found' : tind_record_ids.join(',')
        tind_info << "mmsid #{asset[:mmsid]}: #{tind_ids}"
      end

      { insert: [], append: [], tind_info: }
    end

    def append(asset, f_035, assets)
      asset[:f_035_from_tind] = f_035
      assets.push(asset)
    end

  end
end
