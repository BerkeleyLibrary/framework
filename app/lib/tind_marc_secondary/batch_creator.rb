require_relative 'da_asset'
require_relative 'tind_marc'

module TindMarcSecondary
  class BatchCreator
    attr_accessor :config

    def initialize(args)
      setup(args)
      create_configs(args)
      # Rails.logger.info(@config.display) # checking configurations
    end

    def tind_records_hash
      assets_hash = da_assets_hash
      return { insert: [], append: [], messages: assets_hash[:messages] } if assets_hash[:insert].empty? && assets_hash[:append].empty?

      tind_marc = TindMarc.new(@config)
      tind_marc.records_hash(assets_hash)
    end

    def da_assets_hash
      da_asset = DaAsset.new(@config.da_batch_path, @config.verify_tind)
      da_asset.assets_hash
    end

    private

    def setup(args)
      BerkeleyLibrary::Alma::Config.default!
      BerkeleyLibrary::TIND::Mapping::AlmaBase.collection_parameter_hash = {
        '336' => [args[:resource_type]],
        '852' => [args[:library]],
        '980' => [args[:f_980_a]],
        '982' => [args[:f_982_a], args[:f_982_b]],
        '991' => args[:restriction].empty? ? [] : [args[:restriction]]
      }
    end

    def create_configs(args)
      incoming_path = args[:directory].delete_prefix('/')
      da_dir = Rails.application.config.tind_data_root_dir
      da_batch_path = File.join(da_dir, incoming_path)
      @config = Config.new(incoming_path, da_batch_path,
                           da_label_file_path(da_batch_path),
                           base_url(incoming_path),
                           prefix_035(incoming_path, args),
                           collection_subfields_tobe_updated(args),
                           create_collection_fields(args),
                           notify?(args))
    end

    def create_collection_fields(args)
      [
        create_field(args, :f_540_a, '540', 'a'),
        create_field(args, :initials, '902', 'n'),
        create_field_902(args)
      ].compact
    end

    def create_field(args, sym, tag, sf)
      return if args[sym].nil?

      ::MARC::DataField.new(tag, ' ', ' ', [sf, args[sym]])
    end

    def create_field_902(args)
      ::MARC::DataField.new('902', ' ', ' ', %w[d #{Date.today.to_s}], ['n', "syscript - #{args[:initials]}"])
    end

    def da_label_file_path(da_batch_path)
      File.join(da_batch_path, 'labels.csv')
    end

    def base_url(incoming_path)
      "https://digitalassets.lib.berkeley.edu/#{incoming_path}/"
    end

    # TODO: to figure out other collections which use f_982_a, or this could be something a user inputs from interface
    def prefix_035(incoming_path, args)
      incoming_path.include?('aerial/ucb') ? "(#{args[:f_982_a]})" : "(#{args[:f_980_a]}"
    end

    def collection_subfields_tobe_updated(args)
      args[:f_982_p].empty? ? {} : { '982' => { 'p' => args[:f_982_p] } }
    end

    def notify?(args)
      args[:verify_tind] == '1'
    end

  end
end
