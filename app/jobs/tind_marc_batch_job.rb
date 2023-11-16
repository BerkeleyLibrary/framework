class TindMarcBatchJob < ApplicationJob
  queue_as :default

  def perform(params, email)
    b = TindMarc::BatchCreator.new(params, email)
    b.prepare
    b.produce_marc(b.assets)
    b.send_email
    # This is only temporary while setting this up
    b.print_out
  end

end
