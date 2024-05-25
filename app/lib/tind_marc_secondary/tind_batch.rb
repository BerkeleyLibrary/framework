require 'berkeley_library/tind'

module TindMarcSecondary

  class TindBatch
    def initialize(config)
      @messages = []
      @config = config
    end

    def records_hash(hash)
      insert = create_insert_records(hash[:insert])
      append = hash.key?(:append) ? create_append_records(hash[:append]) : []

      { insert:, append: }
    end

    private

    def create_insert_records(assets)
      assets.map { |asset| insert_record(asset) }
    end

    # different
    def create_append_records(assets)
      ls = assets.map { |asset| append_record(asset) }
      @insert_records = ls
    end

    def insert_record(asset)
      tind_marc = BerkeleyLibrary::TIND::Mapping::AlmaSingleTIND.new
      additional_fields = (@config.collection_fields + ffts(asset[:folder_name])).append(f_035(asset[:mmsid]))
      rec = tind_marc.record(asset[:mmsid], additional_fields)
      update_field(rec)
      rec
    rescue StandardError => e
      Rails.logger.debug "Couldn't create marc record for #{asset[:mmsid]}. #{e}"
      @messages << "Couldn't create marc record for #{asset[:mmsid]}. #{e}"
    end

    def append_record(asset)
      asset
    rescue StandardError => e
      Rails.logger.debug "Couldn't create marc record for #{asset[:mmsid]}. #{e}"
      @messages << "Couldn't create marc record for #{asset[:mmsid]}. #{e}"
    end

    def update_field(rec)
      hash = @config.collection_subfields_tobe_updated
      Rails.logger.info "UpdatingWWWW1: #{hash.inspect}"
      BerkeleyLibrary::TIND::Mapping::TindRecordUtil.update_record(rec, hash) unless hash.empty?
    end

    def ffts(folder_name)
      hash = label_hash
      file_desc_list = hash_by_record(hash, folder_name)
      ls = []
      file_desc_list.each do |file, desc|
        ls << ::MARC::DataField.new('FFT', ' ', ' ', ['a', "#{@config.base_url}/#{file}"], ['d', desc])
      end
      ls
    end

    def f_035(mmsid)
      ::MARC::DataField.new('035', ' ', ' ', ['a', "#{@config.prefix_035}#{mmsid}"])
    end

    #  # label csv file column names sequence
    def label_hash
      label_hash = {}
      File.open(@config.da_label_file_path, 'r').each_line do |line|
        description, relative_path = line.split(',')
        label_hash[relative_path.strip] = description.strip
      end
      label_hash.to_a.drop(1).to_h
    end

    def hash_by_record(hash, folder_name)
      filenames = file_path_names(folder_name)
      filenames_from_labels_file = hash.keys
      filenames_without_labels = filenames - filenames_from_labels_file
      raise " No digital files under #{da_batch_path}" if filenames.empty?
      raise "some files have no labels in labels.csv file: #{filenames_without_labels.join(';')}" unless filenames_without_labels.empty?

      hash.select { |k, _v| filenames.include?(k) }
    end

    def file_path_names(folder_name)
      da_record_path = File.join(@config.da_batch_path, folder_name)
      # add limitation to only .jpg, .hocr later?
      file_names = Dir.children(da_record_path).select { |f| File.file?(File.join(da_record_path, f)) }
      file_names.map { |name| "#{folder_name}/#{name}" }
    end
  end
end
