class HoldingsMailer < ApplicationMailer

  class << self
    def error_report_for(task)
      return unless (error_count = task.error_count) > 0

      <<~TXT
        Of #{task.record_count} total records, errors occurred when retrieving information
        for #{error_count}. Please see the spreadsheet for details.
      TXT
    end
  end

  def holdings_results(task)
    headers(to: task.email, subject: 'Your holdings request')
    attach_output_file_for(task)
    locals = locals_for(task)
    mail do |format|
      format.html { render(locals:) }
      format.text { render(locals:) }
    end
  end

  private

  def attach_output_file_for(task)
    return unless (output_file = task.output_file)
    return unless output_file.attached?

    blob = output_file.blob
    attachments[task.output_filename] = {
      mime_type: blob.content_type,
      content: blob.download
    }
  end

  def locals_for(task)
    {
      holdings_task: task,
      error_report: HoldingsMailer.error_report_for(task)
    }
  end

end
