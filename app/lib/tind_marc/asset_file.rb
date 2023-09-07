require 'find'
module TindMarc
  class AssetFile
    attr_reader :file_hash

    # Root dir is the base directory to recursively search for filenames. If you supply a match pattern it will
    # only grab files with that match. e.g. '_k.jpg' if you only want to retrieve files ending with that pattern.
    def initialize(root_dir)
      @file_hash = {}
      filenames(root_dir)
    end

    def create_key(path)
      key = File.basename(path)
#      key.gsub!(/_.*?$/, '')
#      key.gsub!(/\.\w.*?$/, '')
      key.gsub!(/\_\d{1,}\.\w.*?$/, '')
      key.gsub!(/\.\w.*?$/,'')
      @file_hash[key] = [] unless @file_hash.key?(key) || File.directory?(path)
      key
    end

    # Creates a hash containing an array of file paths. Each key will contain the files for one Tind record.
    # The expected filename format is mmsid_barcode and the key will be the alma id
    def filenames(root_dir)
      raise StandardError.new("Directory: #{root_dir} not found") unless File.directory?(root_dir)
      Find.find(root_dir) do |path|
        key = create_key(path)
        @file_hash[key] << path if @file_hash.key?(key) 
      end
      @file_hash
    end
  end
end
