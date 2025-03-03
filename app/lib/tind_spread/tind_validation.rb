require 'net/http'
require 'open-uri'
module TindSpread
  module TindValidation

    # runs a set of validations against a single row.
    # Row should be an array of hashes, key being the column header for the row.
    # rubocop:disable Metrics/MethodLength: Method has too many lines. [13/10]
    def self.validate_row(row)
      errors = []
      validate_files(row, errors)

      row.each do |key, value|
        next if value.nil?

        case key
        when /FFT/i
          validate_fft(key, value, errors)
        when /500__3/
          validate_500__3(key, row, value, errors)
        when /\d{3}.*?{2}6/
          validate_800__6(key, row, value, errors)
        end
      end
      errors
    end
    # rubocop:enable Metrics/MethodLength: Method has too many lines. [13/10]

    # private
    class << self
      private

      def filename_error(row, errors)
        f = search_field('Filename', row).empty? ? search_field('filename', row) : search_field('Filename', row)
        add_error(errors, 'Filename', 'No filename or filestub supplied') if f.values[0].nil?
      end

      def files_not_found(row, errors)
        f = search_field('Filename', row).empty? ? search_field('filename', row) : search_field('Filename', row)
        fft = search_field('FFT__a-1', row)
        add_error(errors, 'FFT__a-1', "No files found for #{f.values[0]}") if fft.values[0].nil? && !f.values[0].nil?
      end

      def validate_files(row, errors)
        filename_error(row, errors)
        files_not_found(row, errors)
      end

      # FFT needs to resolve and needs to be either a jpg or pdf
      def validate_fft(key, value, errors)
        add_error(errors, key, "URL: #{value} inaccessible") unless valid_url?(value)
        add_error(errors, key, "URL: #{value} invalid. needs to be .jpg or .pdf") unless fft_jpg_or_pdf?(value)
      end

      # If there is a 500__3 there needs to be a corresponding 500__a
      def validate_500__3(key, row, value, errors)
        return if valid_500__3?(key, row)

        add_error(errors, key, "There is a 500__3 without a corresponding 500__a. Value for #{clean_header(key)} is #{value}")
      end

      # If there is a __6 there needs to be a corresponding 800__6 referencing the field.
      def validate_800__6(key, row, value, errors)
        add_error(errors, key, "There is no matching $6 for value #{value}") unless corresponding_6?(key, row)
      end

      def add_error(errors, key, message)
        errors << "header: #{clean_header(key)} #{message}"
      end

      # There can be repeated fields. We need to search them all to make sure 880's have a corresponding field with a $6
      def get_sub_6_fields(row, stub)
        stub =~ /^(\d{3})/
        # stub = $1
        stub = Regexp.last_match(1)
        row.select { |key| key.to_s.match(/#{stub}.*?{2}6/) }
      end

      # sometimes there's some garbage data added to $6 value that can be ignored.
      # We'll only use the the "\d\d\d-\d\d" e.g. "111-11" part of the value in the spreadsheet cell
      def clean_sub_6_field(value)
        value =~ /(\d{3}-\d{2})/
        Regexp.last_match(1)
      end

      def clean_header(header)
        header.gsub(/^\d+:/, '')
      end

      def get_6_order(value)
        value =~ /\d{3}-(\d+)$/
        Regexp.last_match(1)
      end

      def corresponding_6?(key, row)
        value_field_6 = clean_sub_6_field(row[key])
        value_field_6_ref = get_sub_6_fields(row, value_field_6)
        return false if value_field_6_ref.empty?

        value_field_6_ref.each do |_key, value|
          return true if get_6_order(value_field_6).eql? get_6_order(clean_sub_6_field(value))
        end

        false
      end

      def fft_jpg_or_pdf?(url)
        return true if url.gsub(/\s+$/, '') =~ /\.jpg$|\.pdf$/

        false
      end

      # rubocop:disable Metrics/MethodLength: Method has too many lines.
      def valid_url?(url)
        begin
          uri = URI.parse(url.gsub(/\s/, ''))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == 'https')
          http.read_timeout = 5 # seconds

          request = Net::HTTP::Get.new(uri.request_uri)
          res = http.request(request)
        rescue StandardError
          return false
        end
        return false unless res.code.match(/200|301|302/)

        true
      end
      # rubocop:enable Metrics/MethodLength: Method has too many lines.

      # This returns a hash of only the desired keys
      def search_field(field, row)
        row.select { |k, _| k =~ /#{field}$/ }
      end

      # If there is a 500__3 there needs to be a corresponding 500__a
      def valid_500__3?(key, row)
        f_500_a = key.gsub('500__3', '500__a')

        # Get a hash for just the 500_a's.
        r = search_field(clean_header(f_500_a), row)

        # return false if there are any 500__3's without a corresponding 500_a
        return false unless r.values.compact.any? { |val| val =~ /\w/ }

        true
      end

    end
  end
end
