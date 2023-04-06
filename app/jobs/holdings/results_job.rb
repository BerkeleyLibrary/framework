module Holdings
  class ResultsJob < HoldingsJobBase

    # @param batch [GoodJob::Batch] the completed batch
    # @param params [Hash] the batch parameters
    def perform(batch, params)
      task = batch.properties[:task]
      logger.info("Starting #{ResultsJob} for batch #{batch.id}", task:, event: params[:event])
      logger.warn("#{task.class} #{task.id} is not complete") if task.incomplete?

      task.ensure_output_file!

      HoldingsMailer.holdings_results(task).deliver_now
    end

  end
end
