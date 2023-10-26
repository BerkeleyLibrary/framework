require 'rails_helper'

describe TindMarcBatch do

  attr_reader :form

  describe 'is valid' do
    describe 'form' do
      before do
        params = {
          directory: 'librettos/incoming',
          f_980_a: 'Librettos',
          f_982_a: 'Italian Librettos',
          f_982_b: 'Italian Librettos',
          f_540_a: 'some restriction text',
          resource_type: 'Image',
          library: 'The Bancroft Library',
          email: 'some_email@berkeley.edu'
        }
        @form = TindMarcBatch.new(params)
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
          directory: nil,
          f_980_a: nil,
          f_982_a: nil,
          f_982_b: nil,
          f_540_a: nil,
          resource_type: nil,
          library: nil,
          email: nil,
          f_982_p: nil,
          restriction: nil
        }
      end

      it 'is valid' do
        expect(TindMarcBatch.new(@params).permitted_params).to eq(@params)
      end

    end
  end

  describe 'permitted params are not valid' do
    describe 'form' do
      before do
        @params = {
          directory: nil,
          f_980_a: nil,
          f_982_a: nil,
          f_982_b: nil,
          f_540_a: nil,
          resource_type: nil,
          library: nil,
          email: nil,
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

  # Missing a required parameter should cause it to faile
  describe 'is not valid' do
    describe 'form' do
      before do
        params = {
          directory: 'directory',
          f_982_a: 'Italian Librettos',
          f_982_b: 'Italian Librettos',
          f_540_a: 'some restriction text',
          resource_type: 'Image',
          library: 'The Bancroft Library',
          email: 'some_email.berkeley.edu'
        }
        @form = TindMarcBatch.new(params)
      end

      it 'is not valid' do
        expect(@form.valid?).to eq(false)
      end

    end
  end
end
