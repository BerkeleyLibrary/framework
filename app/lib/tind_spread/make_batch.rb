require 'csv'
require_relative 'tind_validation'
require_relative 'spread_tool'

module TindSpread
  module MakeBatch

    def self.added_headers(form_params)
      added_headers = %i[336__a 852__c 540__a 980__a 982__a 982__b 982__p 991__a 902__n]
      form_params.select { |key| added_headers.include?(key) }
    end

    def self.delete_filename(header)
      header.each do |key, _value|
        header.delete(key) if key.to_s.match(/filename/i)
      end
    end

    # Header is a combination from spreadsheet along with form parameters. Some fields
    # in spreadsheet may be excluded if they are duplicated in the form."
    def self.make_header(header, form_params, remove_filename: true)
      delete_filename(header) if remove_filename

      # csv_string = CSV.generate do |csv|
      CSV.generate do |csv|
        h = header.concat(added_headers(form_params).keys.to_a)
        h << '035__a'
        h << '902__d'
        csv << h
      end
      # csv_string
    end

    # Only using the first FFT for the 035
    def self.get_first_fft(row)
      row.each do |key, value|
        return value if key.match?(/FFT__a/i) || key.match?(/FFT__a-/i)
      end
      nil
    end

    # 035 is a combination of the 980__a (from the form), along with the first
    # FFT minus the extension. e.g. "035__a: (VTI)cubanc_GTR01"
    def self.make_035(f980_a, row)
      fft = get_first_fft(row)
      unless fft.nil?
        fft = File.basename(fft).gsub(/\.\w+$/, '')
        return "(#{f980_a})#{fft}"
      end
      # if no FFT use a random number in combination with 980 for the 035
      "(#{f980_a})_#{rand(9_000_000_000)}"
    end

    # Add each row from the spreadsheet along with some form params
    # rubocop:disable Metrics/MethodLength: Method has too many lines.
    # rubocop:disable Metrics/AbcSize: Assignment Branch Condition size for add_row is too high.
    def self.add_row(row, form_params, filename_row: false)
      csv_row = []
      csv_string = ''
      row.merge!(added_headers(form_params))
      csv_string << CSV.generate do |csv|
        row.each do |key, value|
          next if !filename_row && key =~ /Filename/i

          csv_row << value
        end
        csv_row << make_035(form_params[:'980__a'], row)
        csv_row << Time.current.in_time_zone('Pacific Time (US & Canada)').to_date

        csv << csv_row
      end
      csv_string.encode('UTF-8')
    end
    # rubocop:enable Metrics/MethodLength: Method has too many lines.
    # rubocop:enable Metrics/AbcSize: Assignment Branch Condition size for add_row is too high.

  end
end
