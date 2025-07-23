require 'roo'
require_relative 'tind_validation'
require_relative 'make_batch'
require_relative 'spread_tool'

module TindSpread
  class TindBatch

    def initialize(args, xlsx, extension, email)
      @email = email
      @form_info = args
      @xlsx_path = xlsx
      @extension = extension
    end

    def format_errors
      error_message = ''
      @all_errors.each do |line_num, errors|
        error_message << "Errors for Line #{line_num}\n"
        errors.each do |error|
          error_message << "#{error}\n"
        end
        error_message << "\n"
      end
      # File.write('errors.txt', error_message)
      error_message
    end

    def attachments(attachment_name)
      if @all_errors.empty?
        { "#{attachment_name}.csv" => @csv.to_s }
      elsif @csv.count("\n") > 1
        { "#{attachment_name}.csv" => @csv.to_s, "ERRORREPORT_#{attachment_name}.csv" => @errors_csv.to_s,
          "ERRORREPORT_#{attachment_name}.txt" => format_errors }
      else
        { "ERRORREPORT_#{attachment_name}.csv" => @errors_csv.to_s,
          "ERRORREPORT_#{attachment_name}.txt" => format_errors }
      end
    end

    # rubocop:disable Metrics/AbcSize
    def send_email
      attachment_name = "#{@form_info[:'982__a'].gsub(/\s/i, '_')}_#{Time.current.in_time_zone('Pacific Time (US & Canada)').to_date}"
      body = @all_errors.empty? ? 'No errors found' : 'Line number in errors text file corresponds to line number in Errors spreadsheet'
      RequestMailer.tind_spread_email(@email, "Tind batch load for #{@form_info[:'982__a']}", body, attachments(attachment_name)).deliver_now
    end

    # rubocop:disable Metrics/MethodLength
    def create_rows(all_rows)
      row_num = 0
      error_row = 2
      all_rows.each do |row|
        errors = TindSpread::TindValidation.validate_row(row)

        if errors.any?
          @all_errors[error_row] = errors if errors.any?
          error_row += 1
        end

        @csv << TindSpread::MakeBatch.add_row(row, @form_info) unless errors.any?
        @errors_csv << TindSpread::MakeBatch.add_row(row, @form_info, filename_row: true) if errors.any?

        row_num += 1
      end
    end
    # rubocop:enable Metrics/MethodLength

    def run
      t = TindSpread::SpreadTool.new(@xlsx_path, @extension, @form_info[:directory])
      all_rows = t.spread
      @csv = TindSpread::MakeBatch.make_header(t.header(all_rows.first.keys), @form_info).encode('UTF-8')
      @errors_csv = TindSpread::MakeBatch.make_header(t.header(all_rows.first.keys), @form_info, remove_filename: false).encode('UTF-8')
      @all_errors = {}
      create_rows(all_rows)
      @csv.to_s.gsub!("\xEF\xBB\xBF".force_encoding('UTF-8'), '')
      @errors_csv.to_s.gsub!("\xEF\xBB\xBF".force_encoding('UTF-8'), '')
      # File.write('output.csv', @csv)
      # File.write('errors.csv', @errors_csv)
      send_email
    end
    # rubocop:enable Metrics/AbcSize
  end
end
