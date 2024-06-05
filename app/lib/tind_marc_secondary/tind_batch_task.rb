require 'berkeley_library/tind'
require_relative 'batch_creator'

module TindMarcSecondary
  class TindBatchTask
    attr_reader :records_hash

    def initialize(args, email)
      @messages = []
      @email = email
      @args = args
    end

    def run
      batch_creator = BatchCreator.new(@args)
      da_assets_hash = batch_creator.da_assets_hash
      @records_hash = batch_creator.tind_records_hash(da_assets_hash)
      save_to_local if Rails.env.development?
      sent_email
    end

    private
    
    #ToDiscuss, or get feedback from user: currently using the same name pattern as existing batch marc tool
    def attachment_filename(key)
      "#{key}#{@args[:f_980_a].gsub(/\s/i, '_')}_#{Time.zone.today.in_time_zone('Pacific Time (US & Canada)').to_date}.xml"
    end

    def attachment_content(records)
      attachment = ''
      records.each do |rec|
        rec.leader = nil
        attachment << rec.to_s
      end
      attachment
    end

    def generate_attatchments
      attachment_hash = {}
      @records_hash.each do |key, records|
        if key != :messages && records.present?
          attachment_hash[attachment_filename(key)] =
            { mime_type: 'text/xml', content: attachment_content(records) }
        end
      end
      attachment_hash
    end

    def sent_email
      attatchments = generate_attatchments
      subject = attatchments.empty? ? "No batch records created for #{@args[:directory]}" : "Tind batch load for #{@args[:f_982_a]}"
      RequestMailer.tind_marc_batch_2_email(@email, attatchments, subject, @records_hash[:messages]).deliver_now
    end

    # method for get result to test in local
    def save_to_local
      da_dir = Rails.application.config.tind_data_root_dir
      file = File.join(da_dir, 'aerial/ucb/incoming/result.xml')
      writer = BerkeleyLibrary::TIND::MARC::XMLWriter.new(file)

      @records_hash[:append].each do |record|
        Rails.logger.info("66666666#{record.inspect}")
        record.leader = nil

        writer.write(record)
      end
      writer.close
    end

  end
end
