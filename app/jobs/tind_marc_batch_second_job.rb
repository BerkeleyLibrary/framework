class TindMarcBatchSecondJob < ApplicationJob
  queue_as :default

  def perform(args, email)
    task = TindMarcSecondary::TindBatchTask.new(args, email)
    task.run
  end

end
