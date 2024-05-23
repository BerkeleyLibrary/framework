class TindMarcBatchSecondJob < ApplicationJob
  queue_as :default

  def perform(params, email)
    creater = TindMarcSecondary::BatchCreator.new(params, email)
    creater.run
    creater.save_local('result.xml')
  end

end
