require 'rspec'
require 'jobs_helper'
require 'active_support/all'
require 'action_mailer'
require_relative '../../../app/lib/tind_spread/tind_batch'
require_relative '../../../app/lib/tind_spread/tind_validation'
require_relative '../../../app/lib/tind_spread/make_batch'
require_relative '../../../app/lib/tind_spread/spread_tool'

RSpec.describe TindSpread::TindBatch do
  let(:xlsx) { 'path/to/file.xlsx' }
  let(:extension) { :xlsx }
  let(:email) { 'test@example.com' }
  let(:directory) { 'spec/data/tind_validator/data/da/incoming' }
  let(:args) { { directory:, '982__a': 'test' } }
  let(:tind_batch) { described_class.new(args, xlsx, extension, email) }
  let(:spread_tool) { instance_double(TindSpread::SpreadTool) }
  let(:all_rows) { [{ 'Header1' => 'Data1', 'Header2' => 'Data2' }, { 'Header1' => 'Data3', 'Header2' => 'Data4' }] }

  before do
    allow(TindSpread::SpreadTool).to receive(:new).with(xlsx, extension, directory).and_return(spread_tool)
    allow(spread_tool).to receive(:spread).and_return(all_rows)
    allow(spread_tool).to receive(:header).with(any_args).and_return(%w[Header1 Header2])
    allow(TindSpread::MakeBatch).to receive(:make_header).with(any_args).and_return("Header1,Header2\n")
    allow(TindSpread::MakeBatch).to receive(:add_row).with(any_args).and_return("Data1,Data2\n")
    allow(TindSpread::TindValidation).to receive(:validate_row).with(any_args).and_return([])
    # rubocop:disable RSpec/MessageChain
    allow(RequestMailer).to receive_message_chain(:tind_spread_email, :deliver_now)
    # rubocop:enable RSpec/MessageChain
  end

  describe '#initialize' do
    it 'initializes with args, xlsx, extension, and email' do
      expect(tind_batch.instance_variable_get(:@form_info)).to eq(args)
      expect(tind_batch.instance_variable_get(:@xlsx_path)).to eq(xlsx)
      expect(tind_batch.instance_variable_get(:@extension)).to eq(extension)
      expect(tind_batch.instance_variable_get(:@email)).to eq(email)
    end
  end

  describe '#format_errors' do
    it 'formats the errors into a string' do
      tind_batch.instance_variable_set(:@all_errors, { 1 => %w[Error1 Error2], 2 => ['Error3'] })
      expected_result = "Errors for Line 1\nError1\nError2\n\nErrors for Line 2\nError3\n\n"
      expect(tind_batch.format_errors).to eq(expected_result)
    end
  end

  describe '#send_email' do
    it 'sends an email with the correct attachments' do
      tind_batch.instance_variable_set(:@all_errors, {})
      tind_batch.instance_variable_set(:@csv, "Header1,Header2\nData1,Data2\n")
      tind_batch.instance_variable_set(:@errors_csv, "Header1,Header2\n")
      allow(Time).to receive(:current).and_return(Time.parse('2023-10-01 12:00:00 UTC'))
      attachment_name = 'test_2023-10-01'
      expect(RequestMailer).to receive(:tind_spread_email).with(
        email,
        'Tind batch load for test',
        'No errors found',
        { "#{attachment_name}.csv" => "Header1,Header2\nData1,Data2\n" }
      ).and_return(double(deliver_now: true))
      tind_batch.send_email
    end
  end

  describe '#create_rows' do
    it 'creates rows and populates @csv and @errors_csv' do
      tind_batch.instance_variable_set(:@csv, '')
      tind_batch.instance_variable_set(:@errors_csv, '')
      tind_batch.instance_variable_set(:@all_errors, {})
      tind_batch.create_rows(all_rows)
      expect(tind_batch.instance_variable_get(:@csv)).to eq("Data1,Data2\nData1,Data2\n")
      expect(tind_batch.instance_variable_get(:@errors_csv)).to eq('')
    end
  end

  describe '#run' do
    it 'runs the batch process' do
      allow(tind_batch).to receive(:send_email)
      tind_batch.run
      expect(tind_batch.instance_variable_get(:@csv)).to eq("Header1,Header2\nData1,Data2\nData1,Data2\n")
      expect(tind_batch.instance_variable_get(:@errors_csv)).to eq("Header1,Header2\n")
    end
  end
end
