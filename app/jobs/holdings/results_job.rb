module Holdings
  class ResultsJob < HoldingsJobBase

    # @param batch [GoodJob::Batch] the completed batch
    # @param params [Hash] the batch parameters
    def perform(batch, params)
      request = batch.properties[:request]
      logger.info("Starting #{ResultsJob} for batch #{batch.id}", request:, event: params[:event])
      logger.warn("#{request.class} #{request.id} is not complete") if request.incomplete?

      request.ensure_output_file!

      HoldingsMailer.holdings_results(request).deliver_now
    end

  end
end
