require 'berkeley_library/tind'

module TindMarcSecondary

  class TindBatch
    def initialize(config)
      @messages = []
      @config = config
    end

    def record_collection(hash)
      insert = create_insert_records(hash[:insert])
      append = hash.key?(:append) ? create_append_records(hash[:append]) : []

      { insert:, append: }
    end

    private

    def create_insert_records(items)
      Rails.logger.info("RRRRA #{items.inspect}")
      items.map { |item| insert_record(item) }
    end

    def create_append_records(items)
      Rails.logger.info("RRRR #{items.inspect}")
      ls = items.map { |item| append_record(item) }
      @insert_records = ls
    end

    def insert_record(item)
      tind_marc = BerkeleyLibrary::TIND::Mapping::AlmaSingleTIND.new
      additional_fields = (@config.collection_fields + ffts(item[:folder_name])).append(f_035(item[:mmsid]))
      # Rails.logger.info("tttt #{@config.collection_fields.inspect}")
      # additional_fields = [@config.collection_fields] 
      # additional_fields = ffts(item[:folder_name]).append(f_035(item[:mmsid]))
      # additional_fields = [f_035(item[:mmsid])]
      rec = tind_marc.record(item[:mmsid], additional_fields)
      update_field(rec)
      rec
    rescue StandardError => e
      Rails.logger.debug "Couldn't create marc record for #{item[:mmsid]}. #{e}"
      @messages << "Couldn't create marc record for #{item[:mmsid]}. #{e}"
    end

    def append_record(item)
      tind_marc = BerkeleyLibrary::TIND::Mapping::AlmaSingleTIND.new
      additional_fields = (@config.collection_fields + ffts(item[:folder_name])).append(f_035(item[:mmsid]))
      rec = tind_marc.record(alma_id, additional_fields)
      update_field(rec)
      rec
    rescue StandardError => e
      Rails.logger.debug "Couldn't create marc record for #{item[:mmsid]}. #{e}"
      @messages << "Couldn't create marc record for #{item[:mmsid]}. #{e}"
    end

    def update_field(rec)
      hash = @config.collection_subfields_tobe_updated
      Rails.logger.info "UpdatingWWWW1: #{hash.inspect}"
      BerkeleyLibrary::TIND::Mapping::TindRecordUtil.update_record(rec, hash) unless hash.empty?
    end

    def alma_id(folder_name)
      folder_name.split('_')[0]
    end

    def ffts(folder_name)
      hash = label_hash
      file_desc_list = hash_by_record(hash, folder_name)
      ls = []
      file_desc_list.each do |file, desc|
        ls << ::MARC::DataField.new('FFT', ' ', ' ', ['a', "#{@config.base_url}/#{file}"], ['d', desc])
      end
      # Rails.logger.debug "000000000: #{ls.inspect}"
      ls
    end

    def f_035(alma_id)
      # Rails.logger.info "Record99999: #{@prefix_035}#{alma_id}"
      ::MARC::DataField.new('035', ' ', ' ', ['a', "#{@config.prefix_035}#{alma_id}"])
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
