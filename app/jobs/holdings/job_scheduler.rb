module Holdings
  module JobScheduler

    def schedule_jobs(task)
      # TODO: make these run off-hours (wrapper job?)
      #       see https://github.com/bensheldon/good_job/blob/main/README.md#complex-batches
      #       see https://github.com/bensheldon/good_job/blob/main/README.md#cron-style-repeatingrecurring-jobs
      GoodJob::Batch.enqueue(on_finish: Holdings::ResultsJob, task:) do
        Holdings::WorldCatJob.perform_later(task) if task.world_cat?
        Holdings::HathiTrustJob.perform_later(task) if task.hathi?
      end
    end

    class << self
      include JobScheduler
    end
  end
end
