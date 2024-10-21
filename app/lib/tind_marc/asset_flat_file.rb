module TindMarc

  class AssetFlatFile < Asset

    # tind_identification: a value to define a TIND record for flat files under a single directory
    def initialize(batch_info, tind_identification, append_to_id = nil)
      filenames = filenames_from_flat_files(batch_info, tind_identification)
      super(batch_info, tind_identification, filenames, append_to_id)
    end

    private

    def filenames_from_flat_files(batch_info, tind_identification)
      Dir.children(batch_info.da_batch_path).select do |f|
        File.file?(File.join(batch_info.da_batch_path, f)) &&
         Util.valid_file_ext?(f) && f.start_with?(tind_identification)
      end
    end

  end
end
