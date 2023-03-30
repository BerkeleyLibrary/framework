module Holdings
  class ResultsJob < ApplicationJob

    # @param batch [GoodJob::Batch] the completed batch
    # @param params [Hash] the batch parameters
    def perform(batch, params)
      task = batch.properties[:task]
      logger.info("Starting #{ResultsJob} for batch #{batch.id}", task: task, event: params[:event])
      logger.warn("#{task.class} #{task.id} is not complete") if task.incomplete?

      task = task_from(batch)
      task.ensure_output_file!

      # TODO: send email
    end

  end
end
