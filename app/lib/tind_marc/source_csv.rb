module TindMarc

  # assets from SourceCsv are gotten from DA based on the mmsid_tind_info csv file
  class SourceCsv
    def initialize(batch_info)
      @batch_info = batch_info
    end

    def assets
      ls = []
      CSV.foreach(@batch_info.da_mmsid_tind_file_path, headers: true, header_converters: :symbol, encoding: 'bom|utf-8') do |row|
        ls << create_asset(row)
      end
      ls
    end

    private

    def create_asset(row)
      return AssetDirectory.new(@batch_info, row[:mmsid_folder_name], tind_id(row)) if row[:mmsid_folder_name].present?

      AssetFlatFile.new(@batch_info, row[:tind_identification_from_flat_filenames], tind_id(row))
    end

    def tind_id(row)
      id = row[:append_to]
      return if id.blank?

      id.strip
    end
  end
end
