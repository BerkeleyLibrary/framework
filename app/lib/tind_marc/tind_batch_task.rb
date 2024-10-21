module TindMarc
  class TindBatchTask

    def initialize(args, email)
      @email = email
      @args = args
    end

    def run
      batch_creator = TindBatchCreator.new(@args)
      validate_batch_creator(batch_creator)
      records_hash = batch_creator.records_hash
      Output.save_to_local(records_hash, @args[:directory]) if Rails.env.development?
      send_completed_email(records_hash)
    rescue StandardError => e
      # Rails.logger.debug "Faild from creating taskb: #{e.message} - #{e.backtrace.first}"
      Util.send_failed_email(@email, e, 'Cannot create Tind batch, please check with support team.', @args[:directory])
    end

    private

    def validate_batch_creator(batch_creator)
      return if batch_creator.valid?

      Util.raise_error("Critical error, cannot create TIND Marc batch file(#{@args[:directory]}): #{batch_creator.critical_errors.join(';')}")
    end

    def send_completed_email(records_hash)
      attatchments = generate_attatchments(records_hash)
      subject = create_subject(attatchments.keys)
      RequestMailer.tind_marc_batch_2_email(@email, attatchments, subject, '').deliver_now
    end

    def create_subject(attachment_filenames)
      batch_info = "#{@args[:f_982_a]} - #{@args[:directory]}"
      warning_subject = "Warning: no batch xml created for #{batch_info}, please check source data etc."
      completed_subject = "Completed: Tind batch file(s) created for #{batch_info}"
      any_batch_file?(attachment_filenames) ? completed_subject : warning_subject
    end

    def any_batch_file?(attachment_filenames)
      name = attachment_filenames.join(',')
      name.include?('inserts') || name.include?('appends')
    end

    def generate_attatchments(records_hash)
      attachment_hash = {}
      add_batch_attachments(records_hash, attachment_hash)
      add_log_attachment(records_hash, attachment_hash)
      attachment_hash
    end

    def add_batch_attachments(records_hash, attachment_hash)
      %w[inserts appends].each do |type|
        record_list = records_hash[type.to_sym]
        next if record_list.empty?

        attachment_hash[attachment_filename(type)] =
          { mime_type: 'text/xml', content: batch_attachment_content(record_list) }
      end
    end

    def add_log_attachment(records_hash, attachment_hash)
      content = Output.log_content(records_hash, @args[:directory])
      attachment_hash[attachment_filename('log')] =
        { mime_type: 'text/plain', content: }
    end

    # Marc record cannot be converted to xml when leader is either nil or empty
    def batch_attachment_content(records)
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

    def attachment_filename(type)
      incoming_name = @args[:directory].delete_suffix('/').split('/').compact.last
      name =  "#{@args[:f_982_a]}_#{incoming_name}_#{Time.zone.today.in_time_zone('Pacific Time (US & Canada)').to_date}"
      type == 'log' ? "#{name}.log" : "#{type}_#{name}.xml"
    end

    def record_str(rec)
      rec.leader = '          22        4500'
      rec_xml = remove_leader_and_namespace(rec.to_xml)
      rec_xml.to_s
    end

    def remove_leader_and_namespace(rec)
      rec = Nokogiri.XML(rec.to_s)
      rec.search('leader').each(&:remove)
      rec.remove_namespaces!
      rec
    end

  end
end
