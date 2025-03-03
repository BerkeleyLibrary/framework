require 'rspec'
require 'net/http'
require 'open-uri'
require_relative '../../../app/lib/tind_spread/tind_validation'

RSpec.describe TindSpread::TindValidation do
  describe '.validate_row' do
    it 'validates a row and returns errors' do
      row = { 'Filename' => 'value', 'FFT__a' => 'invalid_url', '500__3' => 'value', '800__6' => 'value' }
      allow(described_class).to receive(:valid_url?).with('invalid_url').and_return(false)
      allow(described_class).to receive(:fft_jpg_or_pdf?).with('invalid_url').and_return(false)
      allow(described_class).to receive(:fft_jpg_or_pdf?).with('invalid_url').and_return(false)
      allow(described_class).to receive(:valid_500__3?).with('500__3', row).and_return(false)
      allow(described_class).to receive(:corresponding_6?).with('800__6', row).and_return(false)
      expected_errors = [
        'header: FFT__a-1 No files found for value',
        'header: FFT__a URL: invalid_url inaccessible',
        'header: FFT__a URL: invalid_url invalid. needs to be .jpg or .pdf',
        'header: 500__3 There is a 500__3 without a corresponding 500__a. Value for 500__3 is value',
        'header: 800__6 There is no matching $6 for value value'
      ]
      expect(described_class.validate_row(row)).to eq(expected_errors)
    end
  end

  describe '.validate_fft' do
    it 'validates FFT field and adds errors' do
      errors = []
      allow(described_class).to receive(:valid_url?).with('invalid_url').and_return(false)
      allow(described_class).to receive(:fft_jpg_or_pdf?).with('invalid_url').and_return(false)
      described_class.send(:validate_fft, 'FFT__a', 'invalid_url', errors)
      expect(errors).to include('header: FFT__a URL: invalid_url inaccessible')
      expect(errors).to include('header: FFT__a URL: invalid_url invalid. needs to be .jpg or .pdf')
    end
  end

  describe '.validate_500__3' do
    it 'validates 500__3 field and adds errors' do
      row = { '500__3' => 'value' }
      errors = []
      allow(described_class).to receive(:valid_500__3?).with('500__3', row).and_return(false)
      described_class.send(:validate_500__3, '500__3', row, 'value', errors)
      expect(errors).to include('header: 500__3 There is a 500__3 without a corresponding 500__a. Value for 500__3 is value')
    end
  end

  describe '.validate_800__6' do
    it 'validates 800__6 field and adds errors' do
      row = { '800__6' => 'value' }
      errors = []
      allow(described_class).to receive(:corresponding_6?).with('800__6', row).and_return(false)
      described_class.send(:validate_800__6, '800__6', row, 'value', errors)
      expect(errors).to include('header: 800__6 There is no matching $6 for value value')
    end
  end

  describe '.valid_url?' do
    it 'returns true for a valid URL' do
      url = 'https://example.com'
      stub_request(:get, url).to_return(status: 200)
      expect(described_class.send(:valid_url?, url)).to be true
    end

    it 'returns false for an invalid URL' do
      url = 'https://invalid-url.com'
      stub_request(:get, url).to_return(status: 404)
      expect(described_class.send(:valid_url?, url)).to be false
    end
  end

  describe '.fft_jpg_or_pdf?' do
    it 'returns true for a URL ending with .jpg' do
      url = 'https://example.com/image.jpg'
      expect(described_class.send(:fft_jpg_or_pdf?, url)).to be true
    end

    it 'returns true for a URL ending with .pdf' do
      url = 'https://example.com/document.pdf'
      expect(described_class.send(:fft_jpg_or_pdf?, url)).to be true
    end

    it 'returns false for a URL not ending with .jpg or .pdf' do
      url = 'https://example.com/document.txt'
      expect(described_class.send(:fft_jpg_or_pdf?, url)).to be false
    end
  end

  describe '.valid_500__3?' do
    it 'returns true if there is a corresponding 500__a' do
      row = { '500__3' => 'value', '500__a' => 'value' }
      expect(described_class.send(:valid_500__3?, '500__3', row)).to be true
    end

    it 'returns false if there is no corresponding 500__a' do
      row = { '500__3' => 'value' }
      expect(described_class.send(:valid_500__3?, '500__3', row)).to be false
    end
  end

  describe '.corresponding_6?' do
    it 'returns true if there is a matching $6 field' do
      row = { '800__6' => '111-11', '111__6' => '111-11' }
      expect(described_class.send(:corresponding_6?, '800__6', row)).to be true
    end

    it 'returns false if there is no matching $6 field' do
      row = { '800__6' => '111-11' }
      expect(described_class.send(:corresponding_6?, '800__6', row)).to be false
    end
  end
end
