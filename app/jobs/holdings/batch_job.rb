module Holdings
  class BatchJob < HoldingsJobBase

    def perform(request, result_url)
      # TODO: more elegant handling of failures in ResultsJob
      #       (separate output generation from email?)
      GoodJob::Batch.enqueue(request:, result_url:, on_finish: ResultsJob, on_discard: RequestFailedJob) do
        WorldCatJob.perform_later(request) if request.world_cat?
        HathiTrustJob.perform_later(request) if request.hathi?
      end
    end

    class << self
      def schedule(request, result_url)
        scheduled_at = request.immediate? ? Time.current : start_time
        Holdings::BatchJob
          .set(wait_until: scheduled_at)
          .perform_later(request, result_url)
        request.update(scheduled_at:)
      end

      def start_time
        current_time_pacific = DateTime.current.in_time_zone('America/Los_Angeles')
        tomorrow_midnight_pacific = current_time_pacific.tomorrow.midnight
        tomorrow_midnight_pacific - 45.minutes
      end
    end
  end
end
