class TindValidatorJob < ApplicationJob
  queue_as :default

  #def perform(params, email)
  def perform(params, xlsx, email)
    b = TindSpread::TindBatch.new(params, xlsx, email)
    b.run
    #b.remove_spread
    #b.produce_marc(b.assets)
    #b.send_email
    # This is only temporary while setting this up
    #b.print_out
  end

end
