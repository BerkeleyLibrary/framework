module TindMarc
  module Util

    class << self

      def file_existed?(file_path)
        File.exist?(file_path) && File.file?(file_path)
      end

      def raise_error(txt)
        return if txt.empty?

        Rails.logger.error txt
        raise StandardError, txt
      end

      def identifications_from_flat_filenames(dir_path, flat_file_combination_num)
        ruturn [] if flat_file_combination_num.nil?

        file_path_names_from_flat_files(dir_path).map { |filename| filename_indentify(filename, flat_file_combination_num) }.compact.uniq
      end

      def valid_file_ext?(filename)
        exts = %(.jpg .hocr .pdf)
        exts.include?(File.extname(filename).downcase)
      end

      def send_failed_email(email, e, subject, da_batch_path)
        failed_subject = "#{subject} Directory: #{da_batch_path}"
        failed_message = 'Please see the attached log file for failed information'
        RequestMailer.tind_marc_batch_2_email(email, failed_attachment(e, da_batch_path), failed_subject, failed_message).deliver_now
        Rails.logger.error failed_subject
      end

      def mkdir_at_tmp(name)
        dir_path = Rails.root.join('tmp', name)
        Dir.mkdir(dir_path) unless Dir.exist?(dir_path)
        dir_path
      end

      def create_mmsid_tind_filename(incoming_path)
        "mmsid_tind_#{incoming_path.delete_prefix('/').delete_suffix('/').gsub('/', '_')}.csv"
      end

      def total_mmsid_folders(da_batch_path)
        Dir.children(da_batch_path).select { |f| digit_folder?(f) && File.directory?(File.join(da_batch_path, f)) }
      end

      def get_source_data_root_dir(source_data_root_dir)
        source_data_root_dir.nil? ? Rails.application.config.tind_data_root_dir : source_data_root_dir
      end

      def add_warnings(ls, txt, warnings)
        warnings << "#{txt} \n #{ls.join("\n")}\n"
      end

      def all_files_in_batch(da_batch_path)
        flat_filenames = file_path_names_from_flat_files(da_batch_path)
        dir_filenames = file_paths_from_mmsid_folders(da_batch_path)
        flat_filenames.concat(dir_filenames)
      end

      private

      def filename_indentify(filename, num)
        elements = filename_elements(filename)
        return unless elements.size >= num

        elements.first(num).join('_')
      end

      def filename_elements(filename)
        filename_without_ext = File.basename(filename, File.extname(filename))
        filename_without_ext.split('_')
      end

      def digit_folder?(folder_name)
        str = folder_name.split('_').first.strip
        str.match?(/\A\d+\z/)
      end

      def failed_attachment(e, da_batch_path)
        { 'error_log.txt' => { mime_type: 'text/plain', content: failed_content(e, da_batch_path) } }
      end

      def failed_content(e, da_batch_path)
        content = "Failed to create Tind batch records for: #{da_batch_path}, please reach out to our support team."
        content << "\n"
        content << ('-' * 25)
        content << e.message.to_s
        content << "\n"
      end

      def file_path_names_from_flat_files(dir_path)
        Dir.children(dir_path).select { |f| File.file?(File.join(dir_path, f)) && Util.valid_file_ext?(f) }
      end

      def file_paths_from_mmsid_folders(da_batch_path)
        file_paths = []
        total_mmsid_folders(da_batch_path).each do |folder|
          dir_path = File.join(da_batch_path, folder)
          filenames = file_path_names_from_flat_files(dir_path)
          file_paths_from_folder = filenames.map { |name| File.join(folder, name) }
          file_paths.concat(file_paths_from_folder)
        end
        file_paths
      end

    end

  end
end
