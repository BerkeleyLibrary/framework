require 'rails_helper'

describe MmsidTind do

  attr_reader :form

  describe 'is valid' do
    describe 'form' do
      before do
        params = {
          directory: 'directory_collection/ucb/incoming',
          source_data_root_dir: '/opt/app/spec/data/tind_marc/data/da/'.freeze
        }
        @form = MmsidTind.new(params)
      end

      it 'is valid' do
        expect(@form.valid?).to eq(true)
      end

    end

  end

  # Missing a required parameter should cause it to fail
  describe 'is not valid' do
    describe 'form' do
      before do
        params = {}
        @form = MmsidTind.new(params)
      end

      it 'is not valid' do
        expect(@form.valid?).to eq(false)
      end

    end
  end
end
