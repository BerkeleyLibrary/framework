module TindMarc

  # assets from SourceDa are gotten from DA directly
  class SourceDa

    def initialize(batch_info)
      @batch_info = batch_info
    end

    def assets
      assets_from_directory.concat(flat_file_assets).compact
    end

    private

    def assets_from_directory
      da_batch_path = @batch_info.da_batch_path
      folder_names = Util.total_mmsid_folders(da_batch_path)
      folder_names.map do |folder_name|
        AssetDirectory.new(@batch_info, folder_name)
      end
    end

    def flat_file_assets
      Util.identifications_from_flat_filenames(@batch_info.da_batch_path, @batch_info.flat_file_combination_num).map do |tind_identification|
        AssetFlatFile.new(@batch_info, tind_identification)
      end
    end

  end
end
