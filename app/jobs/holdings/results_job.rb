module Holdings
  class ResultsJob < ApplicationJob
    include BerkeleyLibrary::Holdings

    # @param task [HoldingsTask] the task to report results for
    def perform(task)
      raise ArgumentError, "holdings task: #{holdings_task.id} is not complete" if task.incomplete?

      task.ensure_output_file!
      # TODO: send email
    end

  end
end
