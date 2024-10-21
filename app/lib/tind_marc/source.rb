module TindMarc

  class Source

    def initialize(batch_info)
      @batch_info = batch_info
    end

    def assets
      Util.file_existed?(@batch_info.da_mmsid_tind_file_path) ? csv_assets : da_assets
    end

    private

    def da_assets
      source = SourceDa.new(@batch_info)
      source.assets
    end

    def csv_assets
      source = SourceCsv.new(@batch_info)
      source.assets
    end

  end
end
