module Location
  class RequestFailedJob < LocationJobBase

    # @param batch [GoodJob::Batch] the failed batch
    # @param params [Hash] the batch parameters
    def perform(batch, params)
      batch.properties => { request: }

      logger.info("Starting #{RequestFailedJob} for batch #{batch.id}", request:, event: params[:event])

      errors = GoodJob::Job.discarded.where(batch_id: batch.id).pluck(:error)
      LocationMailer.request_failed(request, errors:).deliver_now
    end
  end
end
