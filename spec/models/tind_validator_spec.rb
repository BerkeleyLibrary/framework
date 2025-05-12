require 'rails_helper'
require 'support/uploaded_file_context'

# describe TindValidator do
RSpec.describe TindValidator, type: :model do
  include_context('uploaded file')
  attr_reader :form

  let(:input_file_path) { Rails.root.join('spec/data/tind_validator/fonoroff_with_errors.csv').to_s.freeze }
  let(:input_file_basename) { File.basename(input_file_path) }

  describe 'is valid' do
    describe 'form' do
      before do
        params = {
          '980__a': 'Librettos',
          '982__a': 'Italian Librettos',
          '982__b': 'Italian Librettos',
          '982__p': 'Some larger project',
          '540__a': 'some restriction text',
          '336__a': 'Image',
          '852__c': 'The Bancroft Library',
          '902__n': 'DMZ',
          input_file: uploaded_file_from(input_file_path, mime_type: mime_type_xlsx),
          '991__a': 'Resticted2Admin'
        }
        @form = TindValidator.new(params)
      end

      it 'is valid' do
        expect(@form.valid?).to eq(true)
      end

    end
  end

  describe 'permitted params are valid' do
    describe 'form' do
      before do
        @params = {
          directory: '/some/directory',
          '980__a': 'Librettos',
          '982__a': 'Italian Librettos',
          '982__b': 'Italian Librettos',
          '982__p': 'Some parent collection',
          '540__a': 'some restriction text',
          '336__a': 'Image',
          '852__c': 'The Bancroft Library',
          '902__n': 'DMZ',
          '991__a': 'Restricted2Bancroft'
        }
      end

      it 'is valid' do
        expect(TindValidator.new(@params).permitted_params).to eq(@params)
      end

    end
  end

  describe 'has non-permitted params' do
    describe 'form' do
      before do
        @params = {
          initials: nil,
          directory: nil,
          f_980_a: nil,
          f_982_a: nil,
          f_982_b: nil,
          f_540_a: nil,
          resource_type: nil,
          library: nil,
          f_982_p: nil,
          restriction: nil,
          fail: nil
        }
      end

      it 'is not valid' do
        expect(TindValidator.new(@params).permitted_params).not_to eq(@params)
      end

    end
  end

  # Missing a required parameter should cause it to fail
  describe 'is not valid' do
    describe 'form' do
      before do
        params = {
          '980__a': 'Librettos',
          '982__a': 'Italian Librettos',
          '982__b': 'Italian Librettos',
          '982__p': 'Some parent collection',
          '540__a': 'some restriction text',
          '336__a': 'Image',
          input_file: uploaded_file_from(input_file_path),
          '902__n': 'DMZ',
          '991__a': 'Restricted2Bancroft'
        }
        @form = TindValidator.new(params)
      end

      it 'is not valid' do
        expect(@form.valid?).to eq(false)
      end

    end
  end
end
