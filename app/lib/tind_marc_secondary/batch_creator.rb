require 'berkeley_library/tind'
require_relative 'da_batch'
require_relative 'tind_batch'
require_relative 'col'

module TindMarcSecondary
  class BatchCreator
    # include Config

    def initialize(args, email)
      @verify_tind = false
      @messages = []
      @email = email
      @config = Col.new(args)
    end

    def run
      da_batch = DaBatch.new(@config, @verify_tind)
      tind_batch = TindBatch.new(@config)
      tind_batch.record_collection(da_batch.item_collection)
    end

    # method for get result to test
    def save_local(file)
      writer = BerkeleyLibrary::TIND::MARC::XMLWriter.new(file)

      @insert_records.each do |record|
        Rails.logger.info("66666666#{record.inspect}")
        record.leader = nil

        writer.write(record)
      end
      writer.close
    end

  end
end
