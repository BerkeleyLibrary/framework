require 'roo'
require_relative 'tind_validation'

module TindSpread
  # rubocop:disable Metrics/ClassLength
  class SpreadTool

    def initialize(xlsx_path, extension, directory)
      @extension = extension
      @xlsx_path = xlsx_path
      @directory = directory
      @worksheet = open_spread
    end

    def open_spread
      xlsx = Roo::Spreadsheet.open(@xlsx_path, extension: @extension)
      @worksheet = xlsx.sheet(0)
    end

    def spread
      unique_headers = unique_header_names
      spread_to_hash(unique_headers)
    end

    def headers
      @worksheet.row(1)
    end

    def unique_header_names
      unique_headers = []
      count = 0
      headers.each do |header|
        new_header = "#{count}:#{header}"
        unique_headers << new_header
        count += 1
      end
      unique_headers
    end

    def header(row)
      row.map do |key|
        key.gsub(/\d+:/, '')
      end
    end

    def delete_unnecessary_fields(all)
      remove = %w[035__a 980__a 982__a 982__b 982__p 540__a 852__a 336__a 852__c 902__ 991__a FFT__a]
      all.each_key do |key|
        all.delete(key) if remove.any? { |r| key.to_s.match(/#{r}/) }
      end
      all
    end

    def get_filename(row_data)
      row_data.each do |key, val|
        return val if key =~ /\d:filename/i
      end
    end

    def urls_to_fft(matches)
      count = 1
      h = {}
      matches.each do |url|
        h["FFT__a-#{count}"] = url
        count += 1
      end
      h
    end

    def find_largest(ffts)
      highest = 0
      ffts.each do |h|
        highest = h.count if h.count > highest
      end
      highest
    end

    # rubocop:disable Lint/UselessAssignment
    def get_files(file_pattern)
      dir = "#{Rails.application.config.tind_data_root_dir}/#{@directory.delete_prefix('/')}"
      if file_pattern.nil?
        matches = []
      else
        file_match = file_pattern.gsub(/\.tif/i, '')
        matches = File.directory?("#{dir}/#{file_pattern}") ? Dir.glob("#{dir}/*/#{file_match}*") : Dir.glob("#{dir}/#{file_match}*")
        matches.map! { |i| i.gsub(Rails.application.config.tind_data_root_dir, 'https://digitalassets.lib.berkeley.edu') }
      end
    end
    # rubocop:enable Lint/UselessAssignment

    def get_ffts(all_rows)
      ffts = []
      all_rows.each do |row_data|
        file_pattern = get_filename(row_data)
        ffts << urls_to_fft(get_files(file_pattern))
      end
      ffts
    end

    def prepare_ffts(ffts)
      high = find_largest(ffts)
      ffts.each do |h|
        count = 1
        while count <= high
          h["FFT__a-#{count}"] = nil unless h.key? "FFT__a-#{count}"
          count += 1
        end
      end
    end

    def update_fft(all_rows, ffts)
      count = 0
      all_rows.each do |h|
        fft = ffts[count]
        fft.each do |key, val|
          h[key] = val
        end
        count += 1
      end
    end

    def make_fft(all_rows)
      ffts = get_ffts(all_rows)
      prepare_ffts(ffts)
      update_fft(all_rows, ffts)
    end

    def delete_filename_row(all_rows)
      all_rows.each do |row|
        row.each_key do |key|
          row.delete(key) if key.to_s.match(/filename/i)
        end
      end
    end

    # creates an array of hashes, each element represents a line in the spreadsheet.
    # each key in the hash is based on the header column for that row in the spreadsheet.
    def spread_to_hash(header)
      all = []
      2.upto(@worksheet.last_row) do |line|
        row_data = header.zip(@worksheet.row(line)).to_h
        delete_unnecessary_fields(row_data)
        all << row_data
      end

      make_fft(all) if header.any? { |val| /filename/i =~ val }
      all
    end

  end
  # rubocop:enable Metrics/ClassLength
end
