module TindMarc

  class BatchInfo
    attr_reader :incoming_path, :da_batch_path, :mmsid_tind_filename, :da_mmsid_tind_file_path, :base_url, :prefix_035, :file_label_hash,
                :flat_file_combination_num

    # incoming_path: directory path from interface
    def initialize(args, prefix_035 = '')
      @incoming_path = args[:directory].delete_prefix('/')
      @da_batch_path = File.join(args[:source_data_root_dir], @incoming_path)
      @mmsid_tind_filename = Util.create_mmsid_tind_filename(args[:directory])
      @da_mmsid_tind_file_path = da_batch_csv_file_path(@mmsid_tind_filename)
      @base_url = "https://digitalassets.lib.berkeley.edu/#{@incoming_path}/"
      @prefix_035 = prefix_035
      @file_label_hash = {}
      @flat_file_combination_num = num_inputted(args)
    end

    def create_label_hash
      file_path = da_batch_label_file_path
      @file_label_hash = csv_to_hash(file_path) if File.file?(file_path)
    end

    def da_batch_label_file_path
      da_batch_csv_file_path('labels.csv')
    end

    private

    def clean_up(description)
      return '' if description.blank?

      numerical_lable_prefix = 'afakeprefix_'
      description.gsub(numerical_lable_prefix, '').strip
    end

    def csv_to_hash(file_path)
      csv_hash = {}
      File.open(file_path, 'r').each_line do |line|
        description, relative_path = line.split(',')
        csv_hash[relative_path.strip] = clean_up(description.strip)
      end

      csv_hash.to_a.drop(1).to_h
    rescue StandardError => e
      txt = "Run into a problem when creating hash from lable.csv file at #{file_path}. #{e}"
      Util.raise_error(txt)
    end

    def da_batch_csv_file_path(filename)
      File.join(@da_batch_path, filename)
    end

    def num_inputted(args)
      return unless args.key?(:mmsid_barcode)

      args[:mmsid_barcode] == '1' ? 2 : 1
    end

  end
end
