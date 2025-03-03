class TindValidatorJob < ApplicationJob
  queue_as :default

  def perform(params, attach, email)
    xlsx = ActiveStorage::Blob.service.path_for(attach.input_file.key)
    extension = attach.input_file.filename.extension
    b = TindSpread::TindBatch.new(params, xlsx, extension, email)
    b.run
    attach.input_file.purge
  end

end
