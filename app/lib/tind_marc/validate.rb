module TindMarc
  module Validate

    class << self

      def mmsid?(id)
        # alma id reg is from :https://github.com/BerkeleyLibrary/alma/blob/main/lib/berkeley_library/alma/constants.rb
        alma_id_reg = /^(?<type>99)(?<unique_part>[0-9]{9,12})(?<institution>[0-9]{4})$/
        alma_id_reg =~ id
      end

      def tind_id?(id)
        return true if id.nil?

        !!(id =~ /\A\d+\z/)
      end

      def label_file(batch_info, errors, warnings)
        file_path = batch_info.da_batch_label_file_path
        return unless Util.file_existed?(file_path)

        required_headers = %w[Label File]
        return unless headers_content?(file_path, required_headers, errors)

        check_filenames_from_csv_have_no_files_on_da(batch_info, warnings)
      end

      def mmsid_tind_file(batch_info, errors, warnings)
        file_path = batch_info.da_mmsid_tind_file_path
        return unless Util.file_existed?(file_path)

        required_headers = %w[mmsid_folder_name tind_identification_from_flat_filenames append_to]
        return unless headers_content?(file_path, required_headers, errors)

        csv_data = CSV.read(file_path, headers: true, encoding: 'bom|utf-8')
        return unless mutually_exclusive?(csv_data, errors)

        compare_da_and_csv(csv_data, warnings, batch_info.da_batch_path)
      end

      private

      def headers_content?(file_path, required_headers, errors)
        csv_data = CSV.read(file_path, headers: true, encoding: 'bom|utf-8')
        headers = csv_data.headers(&:trip)
        missing_headers = required_headers - headers.compact

        errors << "Missing headers: #{missing_headers.join(', ')}" unless missing_headers.empty?
        errors << "No data in the csv file #{file_path}" if csv_data.empty?
        errors.empty?
      rescue StandardError => e
        txt = "Have a problem in reading csv file #{file_path}. #{e}"
        errors << txt
        false
      end

      def mutually_exclusive?(csv_data, errors)
        identical_errors = []
        csv_data.each_with_index do |row, index|
          value_0 = row['mmsid_folder_name']
          value_1 = row['tind_identification_from_flat_filenames']
          add_empty_error(value_0, value_1, index, identical_errors)
          add_duplicated_error(value_0, value_1, index, identical_errors)
        end
        errors.concat(identical_errors)
        identical_errors.empty?
      end

      def add_empty_error(value_0, value_1, index, errors)
        return unless value_0.blank? && value_1.blank?

        errors << "Row #{index + 2}: Both #{value_0.inspect} and #{value_1.inspect} are empty."
      end

      def add_duplicated_error(value_0, value_1, index, errors)
        return unless value_0.present? && value_1.present?

        errors << "Row #{index + 2}: Both #{value_0} and #{value_1}  have values."
      end

      def matching_folders(csv_data, warnings, batch_path)
        folder_names_from_csv = csv_data.pluck('mmsid_folder_name').compact_blank
        folder_names_from_da =  Util.total_mmsid_folders(batch_path)
        return if folder_names_from_csv.sort == folder_names_from_da.sort

        warnings << "Folders listed in mmsid_tind csv file do not match folders in DA:
      from csv file: #{folder_names_from_csv},  from #{batch_path}: #{folder_names_from_da}"
      end

      def compare_da_and_csv(csv_data, warnings, batch_path)
        matching_folders(csv_data, warnings, batch_path)
        # TODO: matching tind_indentification with local flat filenams,
        # when we use the MMSID_TIND information from mmsid_tind csv in future
      end

      def check_filenames_from_csv_have_no_files_on_da(batch_info, warnings)
        label_filenames = batch_info.file_label_hash.keys
        da_filenames = Util.all_files_in_batch(batch_info.da_batch_path)
        filenames_not_on_da = label_filenames - da_filenames
        return if filenames_not_on_da.empty?

        txt = "Below files from labels.csv are not found in DA (#{batch_info.da_batch_path}):"
        Util.add_warnings(filenames_not_on_da, txt, warnings)
      end

    end
  end
end
