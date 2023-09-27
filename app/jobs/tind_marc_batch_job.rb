class TindMarcBatchJob < ApplicationJob
queue_as :default

  def perform(params) 
    b = TindMarc::BatchCreator.new(params)
    b.prepare
    b.produce_marc(b.assets)
    b.send_email
    # This is only temporary while setting this up
    b.print_out
  rescue StandardError => e
    log_error(e)
  end

end
