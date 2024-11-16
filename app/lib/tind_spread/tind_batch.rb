require 'roo'
require_relative './tind_validation'
require_relative './make_batch'
require_relative './spread_tool'

module TindSpread
  class TindBatch

    def initialize(args, xlsx, email)
      @email = email
      @form_info = args
      @xlsx_path = xlsx
    end

    def run
      t = TindSpread::SpreadTool.new(@xlsx_path)
      all_rows = t.get_spread

      @csv = TindSpread::MakeBatch.make_header(t.header(all_rows.first.keys), @form_info)
      @errors_csv = TindSpread::MakeBatch.make_header(t.header(all_rows.first.keys), @form_info)
      all_errors = {} 
      row_num = 0
      error_row = 1 

      all_rows.each do | row |
        errors = TindSpread::TindValidation.validate_row( row )

        if errors.any?
          all_errors[error_row] = errors if errors.any?
          error_row += 1
        end

        @csv << TindSpread::MakeBatch.add_row(row, @form_info) unless errors.any?
        @errors_csv << TindSpread::MakeBatch.add_row(row, @form_info) if errors.any?

        row_num += 1
      end 

      puts @csv
      t.remove_spread

     # attachment_name = "#{@form_info[:'982__a'].gsub(/\s/i, '_')}_#{Time.current.in_time_zone('Pacific Time (US & Canada)').to_date}.csv"
     # RequestMailer.tind_spread_email('test@hotmail.com', "Tind batch load for #{@form_info[:'982__a']}", @messages, attachment_name,
     #   @csv.to_s).deliver_now
      #def send_email 
      #if @records.empty?
      #  RequestMailer.tind_marc_batch_email(@email, "No batch records created for #{@dir}", @messages).deliver_now
      #else
      #  attachment_name = "#{@field_980a.gsub(/\s/i, '_')}_#{Time.current.in_time_zone('Pacific Time (US & Canada)').to_date}.xml"
      #  RequestMailer.tind_marc_batch_email(@email, "Tind batch load for #{@field_982b}", @messages, attachment_name,
      #                                      create_attachment).deliver_now
      #end
      #end

#      puts @errors_csv
#      all_errors.each do | key, values |
#        puts key
#        values.each do | value |
#          puts value
#        end 
#      end
    end
  end
end
