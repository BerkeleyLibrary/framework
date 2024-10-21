module TindMarc
  module Output

    class << self

      def log_content(records_hash, directory_name)
        content = []
        content << "From directory: #{directory_name}\n"
        completed_details = "Total records created: #{records_hash[:inserts].length} inserting; #{records_hash[:appends].length} appending.\n"
        content << completed_details
        errors_hash = records_hash.slice(:errors, :warnings)
        content.concat(format_output(errors_hash))
        content.join("\n")
      end

      def tind_mmsid_log_content(errors)
        errors_hash = { errors: }
        format_output(errors_hash).join("\n")
      end

      def save_to_local(records_hash, directory_name)
        dir_path = Util.mkdir_at_tmp('tind_marc_batch')
        save_batch_xml_file(records_hash[:inserts], dir_path, 'insert_result.xml')
        save_batch_xml_file(records_hash[:appends], dir_path, 'append_result.xml')
        save_log_file(records_hash, dir_path, 'batch.log', directory_name)
      end

      private

      def format(list)
        list.map.with_index { |value, index| "#{index + 1}. #{value}" }
      end

      def format_output(hash)
        ls = []
        hash.each do |key, value|
          next if value.empty?

          ls << key.to_s.capitalize
          ls << ('-' * 25)
          ls.concat(format(value))
          ls << "\n"
        end
        ls
      end

      def save_batch_xml_file(records, dir_path, file)
        return if records.empty?

        file = dir_path.join(file)
        writer = BerkeleyLibrary::TIND::MARC::XMLWriter.new(file)
        records.each do |record|
          record.leader = nil
          writer.write(record)
        end
        writer.close
      end

      def save_log_file(records_hash, dir_path, file, directory_name)
        log_file = dir_path.join(file)
        content = log_content(records_hash, directory_name)
        return if content.nil?

        File.write(log_file, content)
      end
    end
  end
end
