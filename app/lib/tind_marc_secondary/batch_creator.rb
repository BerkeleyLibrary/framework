require 'berkeley_library/tind'
require_relative 'da_asset'
require_relative 'tind_batch'
require_relative 'config'

module TindMarcSecondary
  class BatchCreator
    attr_reader :records_hash
    
    def initialize(args, email)
      @verify_tind = false
      @messages = []
      @email = email
      @config = Config.new(args)
    end

    def run
      da_assets = DaAsset.new(@config, @verify_tind)
      tind_batch = TindBatch.new(@config)
      @records_hash = tind_batch.records_hash(da_assets.map)
    end

    # method for get result to test
    def save_local(file)
      writer = BerkeleyLibrary::TIND::MARC::XMLWriter.new(file)

      @records_hash[:insert].each do |record|
        Rails.logger.info("66666666#{record.inspect}")
        record.leader = nil

        writer.write(record)
      end
      writer.close
    end

  end
end
