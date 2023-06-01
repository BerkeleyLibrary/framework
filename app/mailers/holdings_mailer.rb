class HoldingsMailer < ApplicationMailer

  class << self
    # NOTE: Class method to simplify testing
    def record_errors_for(request)
      return unless (error_count = request.error_count) > 0

      <<~TXT
        Of #{request.record_count} total records, errors occurred when retrieving information
        for #{error_count}. Please see the spreadsheet for details.
      TXT
    end
  end

  delegate :record_errors_for, to: HoldingsMailer

  def holdings_results(request, result_url:)
    raise ArgumentError unless request.output_file_uploaded?

    headers(to: request.email, subject: 'Your holdings request')
    attach_output_file_for(request)

    locals = { result_url:, record_errors: record_errors_for(request) }
    mail do |format|
      format.html { render(locals:) }
      format.text { render(locals:) }
    end
  end

  def request_failed(request, errors:)
    headers(to: request.email, subject: 'Error processing holdings request')

    locals = { errors: }
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
end
