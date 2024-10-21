require 'rails_helper'

describe TindMarcBatch do

  attr_reader :form

  describe 'is valid' do
    describe 'form' do
      before do
        params = {
          directory: 'directory_collection/ucb/incoming',
          flat_file_type: 'MMSID',
          initials: 'DMZ',
          f_980_a: 'Librettos',
          f_982_a: 'Italian Librettos',
          f_982_b: 'Italian Librettos',
          f_540_a: 'some restriction text',
          resource_type: 'Image',
          library: 'The Bancroft Library',
          source_data_root_dir: '/opt/app/spec/data/tind_marc/data/da/'.freeze
        }
        @form = TindMarcBatch.new(params)
      end

      it 'is valid' do
        expect(@form.valid?).to eq(true)
      end

    end
  end

  describe 'has non-permitted params' do
    describe 'form' do
      before do
        @params = {
          directory: nil,
          flat_file_type: nil,
          initials: nil,
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
        expect(TindMarcBatch.new(@params).permitted_params).not_to eq(@params)
      end

    end
  end

  # Missing a required parameter should cause it to fail
  describe 'is not valid' do
    describe 'form' do
      before do
        params = {
          directory: 'directory',
          initials: 'DMZ',
          f_982_a: 'Italian Librettos',
          f_982_b: 'Italian Librettos',
          f_540_a: 'some restriction text',
          resource_type: 'Image',
          library: 'The Bancroft Library'
        }
        @form = TindMarcBatch.new(params)
      end

      it 'is not valid' do
        expect(@form.valid?).to eq(false)
      end

    end
  end
end
