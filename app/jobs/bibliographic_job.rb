class BibliographicJob < ApplicationJob
  queue_as :default

  def perform(host_bib_task)
    host_bib_task.host_bibs.where(marc_status: %w[pending retrieving]).each do |host_bib|
      Bibliographic::HostBib.create_linked_bibs(host_bib)
    end
    after_perform_upload!(host_bib_task)
  rescue StandardError => e
    mark_failed_and_notify!(e, host_bib_task)
  end

  private

  def generate_attatchments(host_bib_task)
    filename = File.basename(host_bib_task.filename, '.*')
    report = Bibliographic::Report.new(host_bib_task, host_bib_task.host_bibs.size)
    # report.save_to_local if Rails.env.development?
    attachment_hash = {
      "#{filename}_completed.csv" => { mime_type: 'text/csv', content: report.csv_content }
    }
    return attachment_hash if report.log_content.nil?

    attachment_hash["#{filename}_error_log.txt"] = { mime_type: 'text/plain', content: report.log_content }
    attachment_hash
  end

  def mark_failed_and_notify!(e, host_bib_task)
    host_bib_task.failed!
    subject = 'Host Bibliographic Upload - Failed'
    message = 'Host Bibliographic upload failed, please reach out to our support team.'
    RequestMailer.bibliographic_email(host_bib_task.email, [], subject, message).deliver_now
    logger.error "BibliographicJob failed: #{e.message}"
    raise e
  end

  def after_perform_upload!(host_bib_task)
    host_bib_task.succeeded!
    attatchments = generate_attatchments(host_bib_task)
    subject = 'Host Bibliographic Upload - Completed'
    message = 'When there is an attached log file, please review unusual MMS ID information.'
    RequestMailer.bibliographic_email(host_bib_task.email, attatchments, subject, message).deliver_now
  end

end
