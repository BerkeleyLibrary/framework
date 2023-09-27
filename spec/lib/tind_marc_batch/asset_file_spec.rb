require 'rails_helper'

module TindMarc
  RSpec.describe AssetFile do
    let(:expected_path) { 'spec/data/tind_marc/data/da/forestry/incoming' }
    let(:non_match) { '293h34hk34_ucb00129798' }
    let(:assets) { AssetFile.new(expected_path) }
    let(:non_existent_path) { 'spec/data/tind_marc/data/da/non_existent_path/incoming' }
    let(:asset_error) { AssetFile.new(non_existent_path) }
    let(:test_key) { '991074090759706532_C032692057' }

    it 'contains a hash with two keys' do
      expect(assets.file_hash.size).to eq(2)
    end

    it 'expects test_key to have 190 file paths' do
      expect(assets.file_hash[test_key].size).to eq(190)
    end

    it 'expects a non matching file pattern to no be included in return hash' do
      expect(assets.file_hash.key?(non_match)).to eq(false)
    end

    it 'expects a non-existent path to contain an empty hash' do
      expect(asset_error.file_hash.size).to eq(0)
    end
  end
end
