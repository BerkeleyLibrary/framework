class TindMarcBatchJob < ApplicationJob
  queue_as :default

  def perform(args, email)
    task = TindMarc::TindBatchTask.new(args, email)
    task.run
  end

end
