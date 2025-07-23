module Bibliographic
  class Report
    attr_reader :host_bib_task, :retrieved_host_bibs, :mmsids_size

    def initialize(host_bib_task, mmsids_size)
      @host_bib_task = host_bib_task
      @mmsids_size = mmsids_size
      @retrieved_host_bibs = host_bib_task.host_bibs.where(marc_status: 'retrieved')
    end

    # For checking in development
    def save_to_local
      dir_path = Rails.root.join('tmp', 'bib')
      FileUtils.mkdir_p(dir_path)
      report_file = dir_path.join('output.csv')
      CSV.open(report_file, 'w') { |csv| csv_writter(csv) }
      log_file = dir_path.join('log_error.txt')
      File.write(log_file, log_content)
    end

    def csv_content
      CSV.generate { |csv| csv_writter(csv) }
    end

    def log_content
      return if host_errors.empty?

      content = summary
      content << "\n"
      content << ('-' * 50)
      content << host_errors.map.with_index { |error, index| "#{index + 1}. #{error}" }
      content.join("\n")
    end

    private

    def successful_host_bibs
      @successful_host_bibs ||= retrieved_host_bibs.select(&:successful_linked_bibs?)
    end

    def csv_writter(csv)
      csv_rows = successful_host_bibs.flat_map { |host_bib| rows_by_host_bib(host_bib) }
      csv << ['Source MMS ID', '774 MMS ID', '774$t', 'LDR/06', 'LDR/07', '035', 'Count of 774s']
      csv_rows.each { |row| csv << row }
    end

    def rows_by_host_bib(host_bib)
      count = host_bib.linked_bibs.count
      host_bib.linked_bibs.map { |linked_bib| row_by_linked_bib(host_bib, linked_bib, count) }
    end

    def csv_number(val)
      format('%.0d', val)
    end

    def csv_text(val)
      val.presence || '-'
    end

    def row_by_linked_bib(host_bib, linked_bib, count)
      host_bib_mms_id = csv_number(host_bib.mms_id.strip)
      linked_bib_mms_id = csv_number(linked_bib.mms_id.strip)

      host_bib_linked_bib = HostBibLinkedBib.find_by(host_bib:, linked_bib:)
      linked_bib_774t = csv_text(host_bib_linked_bib.code_t)

      ldr_6 = csv_text(linked_bib.ldr_6)
      ldr_7 = csv_text(linked_bib.ldr_7)
      field_035 = csv_text(linked_bib.field_035)
      [host_bib_mms_id, linked_bib_mms_id, linked_bib_774t, ldr_6, ldr_7, field_035, count]
    end

    def failed_host_bibs
      host_bib_task.host_bibs.where(marc_status: 'failed').pluck(:mms_id).map { |mms_id| "Source MMS ID #{mms_id} - no Alma retrieved" }
    end

    def host_bibs_without_744
      retrieved_host_bibs.select(&:without_744?).pluck(:mms_id).map { |mms_id| "Source MMS ID #{mms_id} - Alma retrieved without 774's MMS ID" }
    end

    def host_bibs_with_failed_linked_bib
      retrieved_host_bibs.map do |host_bib|
        linked_bib_mms_ids = host_bib.linked_bibs.where(marc_status: 'failed').pluck(:mms_id)
        next if linked_bib_mms_ids.empty?

        linked_bib_errors = linked_bib_mms_ids.map { |mms_id| "  774 MMS ID #{mms_id} - no Alma retrieved" }
        failed_744(host_bib.mms_id, linked_bib_errors)
      end.compact
    end

    def failed_744(mmsid, ls)
      <<~ERROR
        Source MMS ID #{mmsid} Alma retrieved, but:

        #{ls.join("\n")}
      ERROR
    end

    def hosts_not_processed
      unprocessed_mmsids = host_bib_task.host_bibs.where(marc_status: %w[pending retrieving]).pluck(:mms_id)
      return if unprocessed_mmsids.empty?

      <<~ERROR
        Below Source MMS IDs not processed. You may re-upload them:

        #{unprocessed_mmsids.join("\n")}
      ERROR
    end

    def host_errors
      ls = []
      ls.concat(failed_host_bibs)
      ls.concat(host_bibs_without_744)
      ls.concat(host_bibs_with_failed_linked_bib)
      ls << hosts_not_processed
      ls.compact
    end

    def summary
      ls = ["Total #{mmsids_size} Source MMS IDs:"]
      ls << output(successful_host_bibs, 'successed,')
      ls << output(host_errors, 'failed, please see details below:')
      ls.compact
    end

    def output(ls, txt)
      count = ls.size
      return unless count > 0

      "#{ls.size} #{txt} "
    end

  end
end
