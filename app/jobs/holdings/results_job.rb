module Holdings
  class ResultsJob < ApplicationJob
    include BerkeleyLibrary::Holdings

    RESULT_ARGS = %i[oclc_number wc_symbols wc_error ht_record_url ht_error].freeze

    # @param task [HoldingsTask] the task to report results for
    def perform(task)
      raise ArgumentError, "holdings task: #{holdings_task.id} is not complete" if task.incomplete?

      task.write_output_file!
      # TODO: send email
    end

  end
end
