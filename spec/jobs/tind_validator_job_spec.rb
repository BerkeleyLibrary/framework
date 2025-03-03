require 'rails_helper'

RSpec.describe TindValidatorJob, type: :job do
  let(:params) { { some: 'params' } }
  let(:attach) { double('attach', input_file:) }
  let(:input_file) { double('input_file', key: 'some_key', filename:) }
  let(:filename) { double('filename', extension: 'xlsx') }
  let(:email) { 'test@example.com' }
  let(:blob_service) { double('blob_service') }
  let(:tind_batch) { instance_double(TindSpread::TindBatch, run: true) }

  before do
    allow(ActiveStorage::Blob).to receive(:service).and_return(blob_service)
    allow(blob_service).to receive(:path_for).with('some_key').and_return('/path/to/file.xlsx')
    allow(TindSpread::TindBatch).to receive(:new).with(params, '/path/to/file.xlsx', 'xlsx', email).and_return(tind_batch)
    allow(input_file).to receive(:purge)
  end

  it 'creates a TindBatch and runs it' do
    expect(TindSpread::TindBatch).to receive(:new).with(params, '/path/to/file.xlsx', 'xlsx', email).and_return(tind_batch)
    expect(tind_batch).to receive(:run)
    expect(input_file).to receive(:purge)

    described_class.perform_now(params, attach, email)
  end
end
