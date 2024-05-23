require 'berkeley_library/tind'
require_relative 'da_batch'
require_relative 'tind_batch'

module TindMarcSecondary
  attr_reader  :insert_records, :append_records
  attr_reader  :collection_fields, :prefix_035, :collection_subfields_tobe_updated

  class BatchCreator
    def initialize(args, email)
      @messages = []
      @collection_fields = []
      @collection_subfields_tobe_updated = {}
      @insert_records = []
      @append_records = []
      @batch_path = args[:directory].delete_prefix('/')
      @email = email
      batch_setup(args)
    end

    # class << self
    #   attr_accessor  :insert_records, :append_records
    #   attr_accessor  :collection_fields, :prefix_035, :collection_subfields_tobe_updated
    # end

    def run
      assets = DaBatch.new(@batch_path, false)
      # Rails.logger.info "Batch path%%%%: #{assets.insert_inventory.inspect}"
      create_tind_records(assets.insert_inventory)
      # create_tind_records(assets.append_inventory)
    end

    def save_local(file)
      writer = BerkeleyLibrary::TIND::MARC::XMLWriter.new(file)

      @insert_records.each do |record|
        Rails.logger.info("66666666#{record.inspect}")
        record.leader = nil

        writer.write(record)
      end
      writer.close
    end

    private

    def batch_setup(args)
      BerkeleyLibrary::Alma::Config.default!
      BerkeleyLibrary::TIND::Mapping::AlmaBase.collection_parameter_hash = {
        '336' => [args[:resource_type]],
        '852' => [args[:library]],
        '980' => [args[:f_980_a]],
        '982' => [args[:f_982_a], args[:f_982_b]],
        '991' => args[:restriction].empty? ? [] : [args[:restriction]]
      }
      setup(args)
    end

    def setup(args)
      # add_collection_fields(args)
      @prefix_035 = @batch_path.include?('aerial/ucb') ? "(#{args[:f_982_a]})" : "(#{args[:f_980_a]})"
      @collection_subfields_tobe_updated = args[:f_982_p].nil? ? {} : { '982' => { 'p' => @field_982p } }
    end

    def update_field(rec, hash)
      BerkeleyLibrary::TIND::Mapping::TindRecordUtil.update_record(rec, hash) unless hash.empty?
    end

    def base_url
      "https://digitalassets.lib.berkeley.edu/#{@batch_path}/"
    end

    def alma_id(folder_name)
      folder_name.split('_')[0]
    end

    # # to be defined later
    def prefix(args)
      @batch_path.include?('aerial/ucb') ? "(#{args[:f_982_a]})" : "(#{args[:f_980_a]})"
    end

    def create_tind_records(inventory)
      ls = inventory.items.map { |item| tind_record(item) }
      @insert_records = ls
    end

    def tind_record(item)
      # Rails.logger.debug "Processing######## #{item.inspect} records"
      tind_marc = BerkeleyLibrary::TIND::Mapping::AlmaSingleTIND.new
      alma_id = alma_id(item.folder_name)
      # Rails.logger.debug "Processing######## #{alma_id} records"
      additional_fields = (@collection_fields + ffts(item.file_desc_hash)).append(f_035(alma_id))
      
      # additional_fields.extend(item.file_desc_hash)
      rec = tind_marc.record(alma_id, additional_fields)
      # Rails.logger.info "$$$$$$:"
      # rec = tind_marc.record(alma_id, [f_035(alma_id)])
      # Rails.logger.info "Record$$$$$$: #{rec.inspect}"
      update_field(rec, @collection_subfields_tobe_updated)
      rec
    rescue StandardError => e
      Rails.logger.debug "Couldn't create marc record for #{alma_id}. #{e}"
      @messages << "Couldn't create marc record for #{alma_id}. #{e}"
    end

    def ffts(file_desc_list)
      ls = []
      file_desc_list.each do |file, desc|
        ls << ::MARC::DataField.new('FFT', ' ', ' ', ['a', "#{base_url}/#{file}"], ['d', desc])
      end
      # Rails.logger.debug "000000000: #{ls.inspect}"
      ls
    end

    def f_035(alma_id)
      # Rails.logger.info "Record99999: #{@prefix_035}#{alma_id}"
      ::MARC::DataField.new('035', ' ', ' ', ['a', "#{@prefix_035}#{alma_id}"])
    end

    def add_collection_fields(args)
      add_field(args, :f_540_a, '540', 'a')
      add_field(args, :initials, '902', 'n')
      add_field_902(args)
    end

    def add_field(args, sym, tag, sf)
      # Rails.logger.info "ddd: #{tag}"
      return if args[sym].nil?

      @collection_fields << ::MARC::DataField.new(tag, ' ', ' ', [sf, args[sym]])
    end

    def add_field_902(args)
      f_902 = ::MARC::DataField.new('902', ' ', ' ', %w[d #{Date.today.to_s}], ['n', "syscript - #{args[:initials]}"])
      @collection_fields << f_902
    end
  end
end
