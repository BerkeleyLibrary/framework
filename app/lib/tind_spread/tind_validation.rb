require 'net/http'
require 'open-uri'
module TindSpread
  module TindValidation

    # runs a set of validations against a single row. 
    # Row should be an array of hashes, key being the column header for the row.
    def self.validate_row( row )
      errors = []
      row.each do | key, value |
        case 
        when key.match?(/FFT/)
          next if value.nil?
          #errors << "header: #{key} URL: #{value} inaccessible" unless valid_url?(value)
          errors << "header: #{key} URL: #{value} invalid. needs to be .jpg or .pdf" unless FFT_jpg_or_pdf?(value) 
        when key.match?(/500__3/)
          next if value.nil?
          if !valid_500__3?( key, row )
            errors << "header: #{key} There is a 500__3 without a corresponding 500__a. Value for #{key} is #{value}" 
          end 
#        when key.match?(/880__6/)
#          next if value.nil?
#          has_corresponding_6?(key, row)
#          if !has_corresponding_6?(key, row) 
#            errors << "header: #{key} There is an 880__6 without a corresponding reference field . Missing #{value} for #{key}." 
#          end
        when key.match?(/\d{3}.*?{2}6/)
          next if value.nil?
          has_corresponding_6?(key, row)
          if !has_corresponding_6?(key, row) 
            errors << "header: #{key} There is no matching $6 for #{key}. Missing #{value} for #{key}." 
          end
        end
      end
      errors
    end

  private
 
    # There can be repeated fields. We need to search them all to make sure 880's have a corresponding field with a $6 
    def self.get_sub_6_fields(row, stub)
      stub =~ /^(\d{3})/
      stub = $1
      h = row.select { |key| key.to_s.match(/#{stub}.*?{2}6/)}
    end

    # sometimes there's some garbage data added to $6 value that can be ignored.
    # We'll only use the the "\d\d\d-\d\d" e.g. "111-11" part of the value
    def self.clean_sub_6_field(value)
      value = value 
      value =~ /(\d{3}-\d{2})/ 
      value = $1
    end

    def self.get_6_order(value)
      value =~ /\d{3}-(\d+)$/
      value = $1
    end

    def self.has_corresponding_6?(key, row) 
      value_field_6 = clean_sub_6_field(row[key])
      value_field_6_ref = get_sub_6_fields(row, value_field_6)
      return false if value_field_6_ref.empty? 
  
      value_field_6_ref.each do |kkey, value|
        return true if get_6_order(value_field_6).eql? get_6_order(clean_sub_6_field(value))
      end 

      return false
    end

    def self.FFT_jpg_or_pdf?(url)
      url =~ /\.jpg$|\.pdf$/ 
    end
    
    def self.valid_url?(url)
      #url = url.gsub('/incoming/','/text/')
      begin
        uri = URI.parse(url.gsub(/\s/,''))
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.read_timeout = 5 # seconds

        request = Net::HTTP::Get.new(uri.request_uri)
        res = http.request(request)
      rescue => error
        return false
      end
      return false unless res.code.match(/200|301|302/)
      true
    end

    # If there is a 500__3 there needs to be a corresponding 500__a
    def self.valid_500__3? ( key, row ) 
      f_500_a = key.gsub('500__3', '500__a')
      return false unless row.key? f_500_a && !row[f_500_a].nil? 
      #return false unless row.any? { |hash| hash.key?(f_500_a.to_s) }
      true 
    end

  end
end
