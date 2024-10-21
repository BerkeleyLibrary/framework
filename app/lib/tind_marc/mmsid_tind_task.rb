module TindMarc
  class MmsidTindTask

    def initialize(args, email)
      @email = email
      @batch_info = BatchInfo.new(args)
    end

    def run
      tind_mmsid_creator = MmsidTindCsvCreater.new(@batch_info)
      rows = tind_mmsid_creator.rows
      errors = tind_mmsid_creator.errors
      save_to_local(rows) if Rails.env.development?
      send_completed_email(rows, errors)
    rescue StandardError => e
      Util.send_failed_email(@email, e, 'Critical error, cann not obtain TIND and MMSID CSV file', @batch_info.da_batch_path)
    end

    def send_completed_email(rows, errors)
      completed_message = 'Please see the attached file for TIND and MMSID information.'
      completed_subject = "Completed to obtain TIND and MMSID information for the batch at: #{@batch_info.da_batch_path
                                                                                            }"
      RequestMailer.tind_marc_batch_2_email(@email, generate_attatchments(rows, errors), completed_subject, completed_message).deliver_now
    end

    private

    def generate_attatchments(rows, errors)
      attachments = {
        @batch_info.mmsid_tind_filename => { mime_type: 'text/csv', content: csv_content(rows) }
      }
      add_log_attachment(errors, attachments)
      attachments
    end

    def add_log_attachment(errors, attachments)
      return if errors.empty?

      content = Output.tind_mmsid_log_content(errors)
      attachments["#{@batch_info.incoming_path}.log"] =
        { mime_type: 'text/plain', content: }
    end

    def csv_content(rows)
      CSV.generate { |csv| csv_writter(csv, rows) }
    end

    def csv_writter(csv, rows)
      rows.each { |row| csv << row }
    end

    # For checking in development environment
    def save_to_local(rows)
      dir_path = Util.mkdir_at_tmp('mmsid_tind')
      tind_mmsid_file = dir_path.join(@batch_info.mmsid_tind_filename)
      CSV.open(tind_mmsid_file, 'w') { |csv| csv_writter(csv, rows) }
    end

  end
end
