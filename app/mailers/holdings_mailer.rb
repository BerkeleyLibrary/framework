class HoldingsMailer < ApplicationMailer

  class << self
    def error_report_for(request)
      return unless (error_count = request.error_count) > 0

      <<~TXT
        Of #{request.record_count} total records, errors occurred when retrieving information
        for #{error_count}. Please see the spreadsheet for details.
      TXT
    end
  end

  def holdings_results(request, result_url)
    headers(to: request.email, subject: 'Your holdings request')
    attach_output_file_for(request)
    locals = locals_for(request).merge(result_url:)
    mail do |format|
      format.html { render(locals:) }
      format.text { render(locals:) }
    end
  end

  private

  def attach_output_file_for(request)
    return unless (output_file = request.output_file)
    return unless output_file.attached?

    blob = output_file.blob
    attachments[request.output_filename] = {
      mime_type: blob.content_type,
      content: blob.download
    }
  end

  def locals_for(request)
    {
      holdings_request: request,
      error_report: HoldingsMailer.error_report_for(request)
    }
  end

end
