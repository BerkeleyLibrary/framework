require 'find'
module TindMarc
  class AssetFile
    attr_reader :file_inventory, :messages

    # Root dir is the base directory to recursively search for filenames. If you supply a match pattern it will
    # only grab files with that match. e.g. '_k.jpg' if you only want to retrieve files ending with that pattern.
    def initialize(root_dir)
      @file_inventory = {}
      @messages = ''
      populate_inventory(root_dir)
    end

    def create_key(path)
      file_base = File.basename(path)
      /(?<key>^\d+_[a-zA-Z0-9]+)[_|.]/i =~ file_base

      @messages << "Could not get Alma ID for #{path}\n" if key.nil? && File.file?(path)

      key.tap do |k|
        @file_inventory[k] ||= [] unless File.directory?(path) || key.nil?
      end
    end

    # Creates a hash containing an array of file paths. Each key will contain the files for one Tind record.
    # The expected filename format is mmsid_barcode and the key will be the alma id
    def populate_inventory(root_dir)
      begin
        Find.find(root_dir) do |path|
          key = create_key(path)
          @file_inventory[key] << path if @file_inventory.key?(key)
        end
      rescue StandardError => e
        Rails.logger.error "Directory not found #{e}"
      end
      @file_inventory
    end
  end
end
