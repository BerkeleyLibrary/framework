module Holdings
  class BatchJob < HoldingsJobBase

    def perform(request)
      GoodJob::Batch.enqueue(on_finish: ResultsJob, request:) do
        WorldCatJob.perform_later(request) if request.world_cat?
        HathiTrustJob.perform_later(request) if request.hathi?
      end
    end

    class << self
      def schedule(request)
        job = request.immediate? ? Holdings::BatchJob : Holdings::BatchJob.set(wait_until: start_time)
        job.perform_later(request)
      end

      def start_time
        current_time_pacific = DateTime.current.in_time_zone('America/Los_Angeles')
        tomorrow_midnight_pacific = current_time_pacific.tomorrow.midnight
        tomorrow_midnight_pacific - 45.minutes
      end
    end
  end
end
