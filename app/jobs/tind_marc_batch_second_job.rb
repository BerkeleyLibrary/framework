class TindMarcBatchSecondJob < ApplicationJob
  queue_as :default

  def perform(params, email)
    creater = TindMarcSecondary::TindBatchTask.new(TindMarcBatch.new(params).permitted_params, email)
    creater.run
  end

end
