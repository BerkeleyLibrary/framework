module TindMarc

  class Asset

    attr_accessor :mmsid, :append_to_id, :warnings, :errors, :filenames, :digital_source

    def initialize(batch_info, digital_source, filenames, append_to_id = nil)
      @batch_info = batch_info
      @digital_source = digital_source
      @filenames = filenames
      @append_to_id = append_to_id
      @mmsid = digital_source.split('_')[0].strip
      @warnings = []
      @errors = []
      validate
    end

    def tind_control_f_001
      ::MARC::ControlField.new('001', @append_to_id)
    end

    def f_035
      ::MARC::DataField.new('035', ' ', ' ', ['a', "#{@batch_info.prefix_035}#{@digital_source}"])
    end

    def ffts
      generate_ffts(@filenames)
    end

    def validate
      @errors << "A record was not created due to invalid MMSID #{@mmsid}" unless Validate.mmsid?(@mmsid)

      unless Validate.tind_id?(@append_to_id)
        @errors << "An appending record was not created because the TIND ID is not numerical. '#{@append_to_id}'"
      end

      return unless @filenames.empty?

      @errors << "A record could not be created due to the absence of digital files, possibly caused by : 1) directory #{@digital_source} not existed,
       2) no digital files under directory #{@digital_source},
       or 3) no flat file name started with #{@digital_source}"
    end

    def valid?
      @errors.empty?
    end

    private

    def generate_ffts(file_names)
      return ffts_without_labels_file(file_names) if @batch_info.file_label_hash.empty?

      ffts_with_labels_file(file_names)
    end

    # Allowing some digital files in the lables.csv file to have no label descriptions
    def ffts_with_labels_file(da_filenames)
      file_description_hash = @batch_info.file_label_hash.select { |k, _v| da_filenames.include?(k) }
      ffts_with_label = ffts_with_description_on_csv(file_description_hash)

      filenames_without_label = filenames_no_labels_in_csv_file(da_filenames)
      ffts_without_label = filenames_without_label.map { |file| create_fft(file) }

      (ffts_with_label + ffts_without_label).compact
    end

    def ffts_with_description_on_csv(file_description_hash)
      ffts = []
      file_description_hash.each do |file, description|
        @warnings << "This file (#{file}) in labels.csv file misses description value" if description.blank?
        ffts << create_fft(file, description)
      end
      ffts
    end

    def ffts_without_labels_file(filenames)
      filenames.map { |name| create_fft(name) }
    end

    def create_fft(file, description = nil)
      subfields = [['a', "#{@batch_info.base_url}#{file}"]]
      subfields << ['d', description] if description.present?

      ::MARC::DataField.new('FFT', ' ', ' ', *subfields)
    end

    def filenames_no_labels_in_csv_file(da_filenames)
      label_filenames = @batch_info.file_label_hash.keys
      filenames_missing_labels = da_filenames - label_filenames
      unless filenames_missing_labels.empty?
        txt = "Below files from DA ( #{@batch_info.incoming_path} ) have no labels because they are not listed in labels.csv:"
        Util.add_warnings(filenames_missing_labels, txt, @warnings)
      end
      filenames_missing_labels
    end
  end
end
