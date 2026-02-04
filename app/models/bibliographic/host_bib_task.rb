module Bibliographic
  class HostBibTask < ActiveRecord::Base
    has_many :host_bibs, dependent: :destroy
    enum :status, {
      starting: 0,
      succeeded: 6,
      failed: 9
    }, default: :starting
    validates :email, presence: true

    class << self
      def create_from!(file, email)
        filename = file.original_filename
        host_bib_task = Bibliographic::HostBibTask.new(filename:, email:)
        mms_ids = File.readlines(file).map(&:strip)
        raise ActiveModel::ValidationError, host_bib_task unless valid_upload?(host_bib_task, file, mms_ids)

        create_bib_task!(host_bib_task, mms_ids)
      end

      private

      def valid_upload?(host_bib_task, file, mms_ids)
        errors = upload_errors(file, mms_ids)
        return true if errors.empty?

        errors.each { |error| host_bib_task.errors.add(:base, error) }
        false
      end

      def upload_errors(file, mms_ids)
        errors = []
        errors.push("The file must be in the '.txt' format") unless file&.original_filename&.match?(/\A*\.txt\z/)
        errors.push('The file is empty') if mms_ids.empty?
        invalid_mms_ids = mms_ids.grep_v(/\A99\d+6532\z/)
        errors.push("Invalid Source MMS IDs - #{invalid_mms_ids.join(', ')}") unless invalid_mms_ids.empty?
        errors
      end

      def create_bib_task!(host_bib_task, mms_ids)
        ActiveRecord::Base.transaction do
          host_bib_task.save!
          attributes = mms_ids.map do |mms_id|
            #  The default value 'pending' won't be included in bulk inserts.
            { mms_id:, host_bib_task_id: host_bib_task.id, marc_status: 'pending' }
          end
          bulk_insert(attributes)
        end
        host_bib_task
      end

      # rubocop:disable Rails/SkipsModelValidations
      def bulk_insert(attributes)
        Bibliographic::HostBib.insert_all(attributes)
      end
      # rubocop:enable Rails/SkipsModelValidations

    end

  end
end
