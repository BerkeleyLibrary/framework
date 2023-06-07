module Location
  class ResultsJob < LocationJobBase

    # @param batch [GoodJob::Batch] the completed batch
    # @param params [Hash] the batch parameters
    def perform(batch, params)
      batch.properties => { request:, result_url: }

      logger.info("Starting #{ResultsJob} for batch #{batch.id}", request:, event: params[:event])
      logger.warn("#{request.class} #{request.id} is not complete") if request.incomplete?

      deliver_results(request, result_url:)
    end

    private

    # TODO: more elegant handling of failures in ResultsJob
    #       (separate output generation from email?)
    def deliver_results(request, result_url:)
      request.ensure_output_file!
      LocationMailer.location_results(request, result_url:).deliver_now
    rescue StandardError => e
      LocationMailer.request_failed(request, errors: [e]).deliver_now
      raise
    end
  end
end
