require 'berkeley_library/tind'

module TindMarcSecondary

  class TindMarc
    def initialize(config)
      @messages = []
      @config = config
    end

    def records_hash(assets_hash)
      insert = create_records(assets_hash, :insert) { |asset| insert_record(asset) }
      append = create_records(assets_hash, :append) { |asset| append_record(asset) }

      { insert:, append:, messages: @messages }
    end

    private

    def create_record?(assets_hash, key)
      assets_hash.key?(key) && !assets_hash[key].empty?
    end

    def create_records(assets_hash, key, &)
      return [] unless create_record?(assets_hash, key)

      assets_hash[key].map(&)
    end

    def insert_record(asset)
      tind_marc = BerkeleyLibrary::TIND::Mapping::AlmaSingleTIND.new
      additional_fields = (@config.collection_fields + ffts(asset[:folder_name])).append(f_035(asset[:mmsid]))
      record = tind_marc.record(asset[:mmsid], additional_fields)
      update_field(record)
      record
    rescue StandardError => e
      Rails.logger.debug "Couldn't create insert marc record for #{asset[:mmsid]}. #{e}"
      @messages << "Couldn't create insert marc record for #{asset[:mmsid]}. #{e}"
    end

    def append_record(asset)
      fields = [tind_f_035(asset[:f_035_from_tind])]
      fields.concat(ffts(asset[:folder_name]))
      record = ::MARC::Record.new
      fields.each { |f| record.append(f) }
      record
    rescue StandardError => e
      Rails.logger.debug "Couldn't create append marc record for #{asset[:mmsid]}. #{e}"
      @messages << "Couldn't create append marc record for #{asset[:mmsid]}. #{e}"
    end

    def update_field(rec)
      hash = @config.collection_subfields_tobe_updated
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

    def tind_f_035(val)
      ::MARC::DataField.new('035', ' ', ' ', ['a', val])
    end

    # label csv file provides the sequence of image and hocr file which listed in a TIND FFT field
    # TODO: format of the csv file to be finalized
    # A csv file with header, first column is label description, sencond column is relative path of a file to collection batch path
    def label_hash
      label_hash = {}
      File.open(@config.da_label_file_path, 'r').each_line do |line|
        description, relative_path = line.split(',')
        label_hash[relative_path.strip] = description.strip
      end
      label_hash.to_a.drop(1).to_h
    end

    # TODICUSS: handle data errror in a different way?
    def hash_by_record(hash, folder_name)
      da_filenames = file_path_names(folder_name)
      label_filenames = hash.keys
      da_filenames_without_labels = da_filenames - label_filenames
      raise " No digital files under #{@config.da_batch_path}" if da_filenames.empty?
      raise "some files have no labels in labels.csv file: #{da_filenames_without_labels.join(';')}" unless da_filenames_without_labels.empty?

      hash.select { |k, _v| da_filenames.include?(k) }
    end

    def file_path_names(folder_name)
      da_record_path = File.join(@config.da_batch_path, folder_name)
      # add limitation to only .jpg, .hocr later?
      file_names = Dir.children(da_record_path).select { |f| File.file?(File.join(da_record_path, f)) }
      file_names.map { |name| "#{folder_name}/#{name}" }
    end
  end
end
