require 'uploaded_file_helper'

RSpec.shared_context('HoldingsTask') do
  include UploadedFileHelper

  let(:input_file_path) { 'spec/data/holdings/input-file.xlsx' }
  let(:oclc_numbers_expected) { File.readlines('spec/data/holdings/oclc_numbers_expected.txt', chomp: true) }

  attr_reader :task

  before do
    # ActiveStorage uses a background job to remove files
    @queue_adapter = ActiveStorage::PurgeJob.queue_adapter
    ActiveStorage::PurgeJob.queue_adapter = :inline

    @task = HoldingsTask.create(
      email: 'dmoles@berkeley.edu',
      filename: 'input-file.xlsx',
      hathi: true,
      rlf: true,
      uc: true,
      input_file: uploaded_file_from(input_file_path)
    )
    task.ensure_holdings_records!
  end

  after do
    # Explicitly purge ActiveStorage files
    HoldingsTask.destroy_all
    ActiveStorage::Blob.unattached.find_each(&:purge_later)
    ActiveStorage::PurgeJob.queue_adapter = @queue_adapter
  end
end
