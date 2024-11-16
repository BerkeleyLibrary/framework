require 'roo'
module TindSpread
  class SpreadTool 

    def initialize(xlsx_path)
			@xlsx_path = xlsx_path
      @worksheet = open_spread
    end

    def open_spread
      xlsx = Roo::Spreadsheet.open(@xlsx_path)
      @worksheet = xlsx.sheet(0)
    end

    def get_spread
      unique_headers = unique_header_names 
      spread_to_hash(unique_headers)
    end

    def get_header
      header = @worksheet.row(1)
    end

    def unique_header_names
      unique_headers = []
      count = 0
      get_header.each do | header |
        new_header = "#{count}:#{header}"
        unique_headers << new_header
        count += 1
      end
      unique_headers
    end
    
    def header(row)
      header = []
      row.each do |key|
        header << key.gsub(/\d+\:/,'')
      end
      header
    end

    def delete_unnecessary_fields(all)
      remove = ['035__a','980__a','982__a','982__b','982__p','540__a','852__a','336__a','852__c','902__','991__a']
      all.each do |key, value|
        if remove.select{|r| key.to_s.match(/#{r}/)}.any? 
          all.delete(key)
        end
      end
      all
    end
     
    # creates an array of hashes, each element represents a line in the spreadsheet.
    # each key in the hash is based on the header column for that row in the spreadsheet. 
		#def spread_to_hash(worksheet, header)
		def spread_to_hash(header)
      all = []
      2.upto(@worksheet.last_row) do |line|
        row_data =  Hash[header.zip @worksheet.row(line)]
        delete_unnecessary_fields(row_data)
        all << row_data
      end
      all
		end 

    def remove_spread
      FileUtils.remove(@xlsx_path)      
    end

  end
end
