require 'rails_helper'
require 'support/build_info_context'

describe BuildInfo do
  include_context('mock build info') do
    describe :info do
      it 'returns the info' do
        expect(info.info).to eq(expected_info)
      end
    end

    describe :to_h do
      it 'returns the info' do
        expect(info.to_h).to eq(expected_info)
      end
    end

    describe :to_hash do
      it 'returns the info' do
        expect(info.to_hash).to eq(expected_info)
      end
    end

    describe 'accessors' do
      it 'returns the build value' do
        BuildInfo::BUILD_VARS.each do |v|
          attr = v.downcase
          expect(info).to respond_to(attr)
          expect(info.send(attr)).to eq(expected_info[v])
        end
      end
    end
  end
end
