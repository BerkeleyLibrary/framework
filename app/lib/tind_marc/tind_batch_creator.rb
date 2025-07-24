module TindMarc
  class TindBatchCreator

    attr_reader :critical_errors, :errors, :warnings

    def initialize(args)
      @args = args
      @tind_collection_info = TindCollectionInfo.new(args)
      @batch_info = BatchInfo.new(args, @tind_collection_info.prefix_035)
      @batch_info.create_label_hash
      setup_tind
      @critical_errors = []
      @errors = []
      @warnings = []
      validate_csv_files
    end

    def records_hash
      assets = Source.new(@batch_info).assets
      prepare_records_hash(assets)
    end

    def validate_csv_files
      Validate.label_file(@batch_info, @critical_errors, @warnings)
      Validate.mmsid_tind_file(@batch_info, @critical_errors, @warnings)
    end

    def valid?
      @critical_errors.empty?
    end

    private

    def prepare_records_hash(assets)
      inserts = []
      appends = []

      assets.each do |asset|
        create_new_record(asset, inserts, appends) if asset.valid?
        @warnings.concat(asset.warnings)
        @errors.concat(asset.errors)
      end
      { inserts:, appends:, errors: @errors.compact, warnings: @warnings.compact }
    end

    def create_new_record(asset, inserts, appends)
      if asset.append_to_id.nil?
        record = create_insert_record(asset)
        inserts << record unless record.nil?
      else
        record = create_append_record(asset)
        appends << record unless record.nil?
      end
    end

    def setup_tind
      BerkeleyLibrary::Alma::Config.default!
      BerkeleyLibrary::TIND::Mapping::AlmaBase.collection_parameter_hash = @tind_collection_info.parameter_hash
    end

    def prepare_additional_fields(asset)
      if audio_or_video?
        @tind_collection_info.new_fields + [asset.f_035]
      else
        @tind_collection_info.new_fields + asset.ffts + [asset.f_035]
      end
    end

    def audio_or_video?
      %w[Audio Video].include?(@args[:resource_type])
    end

    def create_insert_record(asset)
      additional_fields = prepare_additional_fields(asset)
      tind_marc = BerkeleyLibrary::TIND::Mapping::AlmaSingleTIND.new
      record = tind_marc.record(asset.mmsid, additional_fields)
      update_subfields(record)
      record
    rescue StandardError => e
      txt = "Couldn't create insert marc record with MMSID #{asset.mmsid}. #{e}"
      @errors << txt
      nil
    end

    def create_append_record(asset)
      fields = [asset.tind_control_f_001]
      fields.concat(asset.ffts)
      record = ::MARC::Record.new
      fields.each { |f| record.append(f) }
      record
    rescue StandardError => e
      txt = "Couldn't create append marc record with MMSID #{asset.mmsid}. #{e}"
      @errors << txt
      nil
    end

    def update_subfields(record)
      hash = @tind_collection_info.subfields_tobe_updated
      BerkeleyLibrary::TIND::Mapping::TindRecordUtil.update_record(record, hash) unless hash.empty?
    end

  end
end
