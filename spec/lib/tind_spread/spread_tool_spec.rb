require 'rspec'
require 'roo'
require 'forms_helper'
require_relative '../../../app/lib/tind_spread/spread_tool'

RSpec.describe TindSpread::SpreadTool do
  let(:xlsx_path) { 'spec/data/tind_validator/fonoroff_with_errors.csv' }
  let(:directory) { 'spec/data/tind_validator/data/da/incoming' }
  let(:extension) { :csv }
  let(:spreadsheet) { double(Roo::Spreadsheet) }
  let(:worksheet) { instance_double(Roo::Excelx::Sheet) }
  let(:spread_tool) { described_class.new(xlsx_path, extension, directory) }

  before do
    allow(Roo::Spreadsheet).to receive(:open).with(xlsx_path, extension:).and_return(spreadsheet)
    allow(spreadsheet).to receive(:sheet).with(0).and_return(worksheet)
    allow(worksheet).to receive(:row).with(1).and_return(%w[Filename Header2])
    allow(worksheet).to receive(:last_row).and_return(3)
    allow(worksheet).to receive(:row).with(2).and_return(%w[Data1 Data2])
    allow(worksheet).to receive(:row).with(3).and_return(%w[Data3 Data4])
    allow(Rails.application.config).to receive(:tind_data_root_dir).and_return('spec/data/tind_spread/data/da/incoming')
  end

  describe '#initialize' do
    it 'initializes with xlsx_path and extension' do
      expect(spread_tool.instance_variable_get(:@xlsx_path)).to eq(xlsx_path)
      expect(spread_tool.instance_variable_get(:@extension)).to eq(extension)
      expect(spread_tool.instance_variable_get(:@directory)).to eq(directory)
    end

    it 'opens the spreadsheet' do
      expect(spread_tool.instance_variable_get(:@worksheet)).to eq(worksheet)
    end
  end

  describe '#open_spread' do
    it 'opens the spreadsheet and returns the first sheet' do
      expect(spread_tool.open_spread).to eq(worksheet)
    end
  end

  describe '#spread' do
    it 'returns an array of hashes representing the spreadsheet data' do
      expected_result = [
        { '0:Filename' => 'Data1', '1:Header2' => 'Data2' },
        { '0:Filename' => 'Data3', '1:Header2' => 'Data4' }
      ]
      expect(spread_tool.spread).to eq(expected_result)
    end
  end

  describe '#headers' do
    it 'returns the headers of the spreadsheet' do
      expect(spread_tool.headers).to eq(%w[Filename Header2])
    end
  end

  describe '#unique_header_names' do
    it 'returns unique header names' do
      expect(spread_tool.unique_header_names).to eq(['0:Filename', '1:Header2'])
    end
  end

  describe '#header' do
    it 'removes numeric prefixes from headers' do
      expect(spread_tool.header(['0:Filename', '1:Header2'])).to eq(%w[Filename Header2])
    end
  end

  describe '#delete_unnecessary_fields' do
    it 'deletes unnecessary fields from the hash' do
      data = { '035__a' => 'value1', 'Filename' => 'value2' }
      expected_result = { 'Filename' => 'value2' }
      expect(spread_tool.delete_unnecessary_fields(data)).to eq(expected_result)
    end
  end

  describe '#spread_to_hash' do
    it 'converts the spreadsheet data to an array of hashes' do
      header = ['0:Filename', '1:Header2']
      expected_result = [
        { '0:Filename' => 'Data1', '1:Header2' => 'Data2' },
        { '0:Filename' => 'Data3', '1:Header2' => 'Data4' }
      ]
      expect(spread_tool.spread_to_hash(header)).to eq(expected_result)
    end
  end
end
