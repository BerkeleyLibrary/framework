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
        if request.immediate?
          scheduled_at = Time.current
          job = Holdings::BatchJob
        else
          scheduled_at = start_time
          job = Holdings::BatchJob.set(wait_until: scheduled_at)
        end
        job.perform_later(request)
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
