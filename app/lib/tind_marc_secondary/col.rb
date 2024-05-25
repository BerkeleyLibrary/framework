module TindMarcSecondary
  class Col
    # @prefix_035 = ''
    # @base_url = ''
    # @collection_subfields_tobe_updated = {}
    # @collectional_fields = []
    # @da_batch_path = ''
    # @da_label_file_path = ''

    attr_accessor :prefix_035, :base_url, :collection_subfields_tobe_updated, :collectional_fields, :da_batch_path, :da_label_file_path
    attr_accessor :collection_fields
    
    def initialize(args)
      setup(args)
    end

    def setup(args)
      BerkeleyLibrary::Alma::Config.default!
      BerkeleyLibrary::TIND::Mapping::AlmaBase.collection_parameter_hash = {
        '336' => [args[:resource_type]],
        '852' => [args[:library]],
        '980' => [args[:f_980_a]],
        '982' => [args[:f_982_a], args[:f_982_b]],
        '991' => args[:restriction].empty? ? [] : [args[:restriction]]
      }
      setup_tind(args)
      setup_da(args)
    end

    private

    def setup_tind(args)
      incoming_path = args[:directory].delete_prefix('/')
      @prefix_035 = incoming_path.include?('aerial/ucb') ? "(#{args[:f_982_a]})" : "(#{args[:f_980_a]}"
      @base_url = "https://digitalassets.lib.berkeley.edu/#{incoming_path}/"
      @collection_subfields_tobe_updated = args[:f_982_p].nil? ? {} : { '982' => { 'p' => args[:f_982_p] } }
      @collectional_fields = create_collection_fields(args)
    end

    def setup_da(args)
      incoming_path = args[:directory].delete_prefix('/')
      @incoming_path = incoming_path
      da_dir = Rails.application.config.tind_data_root_dir
      da_batch_path = File.join(da_dir, incoming_path)
      @da_batch_path = da_batch_path
      @da_label_file_path = File.join(da_batch_path, 'labels.csv')
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

  end
end
