module TindMarc

  class AssetDirectory < Asset
    # fold_name: a sub directory name started with mmsid
    def initialize(batch_info, folder_name, append_to_id = nil)
      filenames = filenames_from_directory(batch_info, folder_name)
      super(batch_info, folder_name, filenames, append_to_id)
    end

    private

    def filenames_from_directory(batch_info, folder_name)
      da_record_path = File.join(batch_info.da_batch_path, folder_name)
      return [] unless File.exist?(da_record_path)

      file_names = Dir.children(da_record_path).select { |f| File.file?(File.join(da_record_path, f)) && Util.valid_file_ext?(f) }
      file_names.map { |name| "#{folder_name}/#{name}" }
    end

  end
end
