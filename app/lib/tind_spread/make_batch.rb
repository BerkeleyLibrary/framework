require 'csv'
require_relative 'tind_validation'
require_relative 'spread_tool'

module TindSpread
  module MakeBatch 

    def self.added_headers(form_params)
      added_headers = [:'336__a', :'852__c', :'540__a', :'980__a', :'982__a', :'982__b', :'982__p', :'991__a', :'902__n']
      h = form_params.select { |key| added_headers.include?(key)} 
    end

    # Header is a combination from spreadsheet along with form parameters. Some fields
    # in spreadsheet may be excluded if they are duplicated in the form."
    def self.make_header(header, form_params)
      csv_string = CSV.generate do |csv|
        h = header.concat(added_headers(form_params).keys.to_a)
        h << '035__a'
        csv << h 
      end
      csv_string 
    end

    # Only using the first FFT for the 035
    def self.get_first_fft(row)
      row.each do |key, value|
        if key.match?(/FFT__a/i) || key.match?(/FFT__a\-/i)
          return value
        end
      end
    end

    # 035 is a combination of the 980__a (from the form), along with the first
    # FFT minus the extension. e.g. "035__a: (VTI)cubanc_GTR01" 
    def self.make_035(f980_a, row)
      fft = get_first_fft(row)
      fft = File.basename(fft).gsub(/\.\w+$/,'') 
      "(#{f980_a})#{fft}"
    end

    # Add each row from the spreadsheet along with some form params
    def self.add_row(row, form_params)
      csv_row = []
      csv_string = ''
      row.merge!(added_headers(form_params))
      csv_string << CSV.generate do |csv|
        row.each do |key, value|
          csv_row << value
        end
        csv_row << make_035(form_params[:'980__a'], row)
        csv << csv_row
      end
      csv_string  
    end

  end
end
