require 'berkeley_library/tind'
require_relative 'batch_creator'
require 'nokogiri'

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
      @records_hash = batch_creator.tind_records_hash
      save_to_local if Rails.env.development?
      sent_email
    end

    private

    # ToDiscuss, or get feedback from user: currently using the same name pattern as existing batch marc tool
    def attachment_filename(key)
      "#{key}_#{@args[:f_980_a].gsub(/\s/i, '_')}_#{incoming_name}_#{Time.zone.today.in_time_zone('Pacific Time (US & Canada)').to_date}.xml"
    end

    # marc record cannot be converted to xml when leader is either nil or empty
    def attachment_content(records)
      attachment = ''
      num = 0
      records.each do |rec|
        rec_xml_str = record_str(rec)
        rec_xml_str = rec_xml_str.gsub('<?xml version="1.0"?>', '') unless num == 0
        attachment << rec_xml_str
        num += 1
      end
      attachment
    end

    def record_str(rec)
      rec.leader = '          22        4500'
      rec_xml = remove_leader_and_namespace(rec.to_xml)
      rec_xml.to_s
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

    def incoming_name
      @args[:directory].split('/').compact.last
    end

    # def sent_email
    #   attatchments = generate_attatchments
    #   batch_info = "#{@args[:f_982_a]} - #{@args[:directory]}"
    #   subject = attatchments.empty? ? "Failed: no batch records created for #{batch_info}" :
    # "Completed: Tind batch records created for #{batch_info}"
    #   RequestMailer.tind_marc_batch_2_email(@email, attatchments, subject, @records_hash[:messages]).deliver_now
    # end
    def tind_information(ls)
      {
        'mmsid_tind_information.txt' => { mime_type: 'text/txt', content: ls.join('\n') }
      }
    end

    def sent_email
      batch_info = "#{@args[:f_982_a]} - #{@args[:directory]}"
      if @records_hash.key?(:tind_info)
        subject = 'MMSID and TIND Information'
        RequestMailer.tind_marc_batch_2_email(@email, tind_information(@records_hash[:tind_info]), subject, 'https://hocr-framework.ucblib.org/tind-marc-batch-test').deliver_now
      else
        attatchments = generate_attatchments
        subject = attatchments.empty? ? "Failed: no record created for #{batch_info}" : "Completed: Tind batch records created for #{batch_info}"
        RequestMailer.tind_marc_batch_2_email(@email, attatchments, subject, @records_hash[:messages]).deliver_now
      end
    end

    def remove_leader_and_namespace(rec)
      rec = Nokogiri.XML(rec.to_s)
      rec.search('leader').each(&:remove)
      rec.remove_namespaces!
      rec
    end

    # method for get result to test in local
    def save_to_local
      insert_file = 'aerial/ucb/incoming/insert_result.xml'
      save_file(@records_hash[:insert], insert_file)
      append_file = 'aerial/ucb/incoming/append_result.xml'
      save_file(@records_hash[:append], append_file)
    end

    # method for get result to test in local
    def save_file(records, file)
      return if records.empty?

      da_dir = Rails.application.config.tind_data_root_dir
      file = File.join(da_dir, file)
      writer = BerkeleyLibrary::TIND::MARC::XMLWriter.new(file)
      records.each do |record|
        Rails.logger.info("save to local: #{record.inspect}")
        record.leader = nil
        writer.write(record)
      end
      writer.close
    end

  end
end
