require 'rspec'
require 'csv'
require 'active_support/all'
require_relative '../../../app/lib/tind_spread/make_batch'

RSpec.describe TindSpread::MakeBatch do
  describe '.added_headers' do
    it 'returns the added headers from form_params' do
      form_params = { '336__a': 'value1', '852__c': 'value2', other_key: 'value3' }
      expected_result = { '336__a': 'value1', '852__c': 'value2' }
      expect(described_class.added_headers(form_params)).to eq(expected_result)
    end
  end

  describe '.make_header' do
    it 'generates a CSV header combining spreadsheet headers and form params' do
      header = %w[Header1 Header2]
      form_params = { '336__a': 'value1', '852__c': 'value2' }
      expected_result = "Header1,Header2,336__a,852__c,035__a,902__d\n"
      expect(described_class.make_header(header, form_params)).to eq(expected_result)
    end
  end

  describe '.get_first_fft' do
    it 'returns the first FFT value from the row' do
      row = { 'FFT__a' => 'value1', 'other_key' => 'value2' }
      expect(described_class.get_first_fft(row)).to eq('value1')
    end
  end

  describe '.make_035' do
    it 'generates the 035 value from f980_a and the first FFT' do
      row = { 'FFT__a' => 'file.txt' }
      f980_a = 'VTI'
      expected_result = '(VTI)file'
      expect(described_class.make_035(f980_a, row)).to eq(expected_result)
    end
  end

  describe '.add_row' do
    it 'adds a row to the CSV string with form params and additional fields' do
      row = { 'Header1' => 'Data1', 'Header2' => 'Data2' }
      form_params = { '980__a': 'VTI', '336__a': 'value1', '852__c': 'value2' }
      allow(Time).to receive(:current).and_return(Time.parse('2023-10-01 12:00:00 UTC'))
      expected_result = "Data1,Data2,VTI,value1,value2,(VTI)file,2023-10-01\n"
      allow(described_class).to receive(:get_first_fft).with(row).and_return('file.txt')
      expect(described_class.add_row(row, form_params)).to eq(expected_result)
    end
  end
end
