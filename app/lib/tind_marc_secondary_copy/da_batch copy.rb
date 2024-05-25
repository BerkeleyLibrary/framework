require 'find'
require_relative 'tind_item_collection'

module TindMarcSecondary
  attr_reader :insert_items, :append_items

  class DaBatch
    def initialize(batch_folder_name, verify_tind)
      @verify_tind = verify_tind
      populate_da_information(batch_folder_name)
      # populate_inventory
    end

    def populate_inventory
      insert_inventory
    rescue StandardError => e
      Rails.logger.error "Inventory not populated: #{e}"
    end
    
    
    private

    def populate_da_information(batch_folder_name)
      da_dir = Rails.application.config.tind_data_root_dir
      @batch_folder_name = batch_folder_name
      @da_batch_path = File.join(da_dir, batch_folder_name)
      @da_label_file_path = File.join(@da_batch_path, 'labels.csv')
      # @da_new_records_file_path = File.join(@da_batch_path, 'new_records.csv')
      # @da_existed_records_file_path = File.join(@da_batch_path, 'existed_records.csv')
    end

    def insert_inventory
      collection = TindItemCollection.new
      hash = label_hash
      Rails.logger.info "!!!! - pp-1"
      mmsid_folder_names.each do |folder_name|
        file_desc_hash = hash_by_record(hash, folder_name)
        collection.add_item(folder_name, nil, file_desc_hash)
      end
      Rails.logger.info "!!!! - pp-2"
      @insert_items = collection
      Rails.logger.info "!!!! - pp3 #{@insert_items.inspect}"
      Rails.logger.info "!!!! - pp"
    end

    def no_csv_files?
      return True unless File.exist?(@da_new_records_file_path) || File.exist?(@da_existed_records_file_path)

      False
    end

    # # folder names with mmsid
    def mmsid_folder_names
      # Rails.logger.info "keys_dd: #{digital_dir_path}"
      # a = Dir.children(@da_batch_path).select { |f| File.directory?(File.join(@da_batch_path, f)) }
      # Rails.logger.info "keys_dd_children: #{a}"
      Dir.children(@da_batch_path).select { |f| File.directory?(File.join(@da_batch_path, f)) }
    end

    # def tind_item(folder_name)
    #   # da_record_path = File.join(@da_batch_path, folder_name)
    #   hash = label_hash
    #   file_desc_hash = hash_by_record(hash, folder_name)
    #   Rails.logger.info "hash_by_record: #{file_desc_hash.keys.join(',')}"
    #   a = TindItem.new(folder_name, nil, file_desc_hash)
    #   Rails.logger.info "hash_by_record11: #{a.class.name}"

    #   a
    # end

    # # keep the order of file listed in the labels.csv file
    def hash_by_record(hash, folder_name)
      filenames = file_path_names(folder_name)
      # Rails.logger.debug "aaaaa: #{filenames.join(',')}"
      
      filenames_from_labels_file = hash.keys
      # Rails.logger.info("bbbbb: #{hash.keys.join(',')}")
      filenames_without_labels = filenames - filenames_from_labels_file
      raise " No digital files under #{da_batch_path}" if filenames.empty?
      raise "some files have no labels in labels.csv file: #{filenames_without_labels.join(';')}" unless filenames_without_labels.empty?

      hash.select { |k, _v| filenames.include?(k) }
    end

    def file_path_names(folder_name)
      da_record_path = File.join(@da_batch_path, folder_name)
      # Rails.logger.info "pppp1: #{da_record_path}"
      # Rails.logger.info "fff5: #{folder_name}"
      # Rails.logger.info "fff0002:"
      # Rails.logger.info "fff1111: #{da_record_path}"
      # Rails.logger.info "fff333:"

      file_names = Dir.children(da_record_path).select { |f| File.file?(File.join(da_record_path, f)) }
      # s =  Dir.children(dir_path).select do |f|
      #   |f| File.file?(File.join(dir_path, f)) 
      # end
      file_names.map {|name| "#{folder_name}/#{name}"}
      # Rails.logger.debug "uuuuu: #{s.join(',')}"
      # s
    end

    def digital_file?(f)
      exts = %w[jpg,hocr]
      exts.include?(f.split('.').last)
    end

    #  # label csv file column names sequence
    def label_hash
      label_hash = {}
      # Rails.logger.info "inventory!!!#{Rails.logger.info "inventory#{@insert_inventory}"}"
      # # /opt/app/data/da/aerial/ucb/incoming
      #   /opt/app/data/da/aerial/ucb/incoming/labels.csv
      File.open(@da_label_file_path, 'r').each_line do |line|
        # Rails.logger.info "!!!!!! -#{line}"
        description, relative_path = line.split(',')
        # Rails.logger.info "key: #{relative_path.strip}"
        label_hash[relative_path.strip] = description.strip
      end
      # Rails.logger.info "!!!EEEE -#{label_hash.keys.join(',')}"
      label_hash.to_a.drop(1).to_h
    end
  end
end
