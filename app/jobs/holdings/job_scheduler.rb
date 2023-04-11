module Holdings
  module JobScheduler

    def schedule_jobs(request)
      # TODO: make these run off-hours (wrapper job?)
      #       see https://github.com/bensheldon/good_job/blob/main/README.md#complex-batches
      #       see https://github.com/bensheldon/good_job/blob/main/README.md#cron-style-repeatingrecurring-jobs
      GoodJob::Batch.enqueue(on_finish: Holdings::ResultsJob, request:) do
        Holdings::WorldCatJob.perform_later(request) if request.world_cat?
        Holdings::HathiTrustJob.perform_later(request) if request.hathi?
      end
    end

    class << self
      include JobScheduler
    end
  end
end
