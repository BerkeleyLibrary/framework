require 'rails_helper'

describe LendingItem, type: :model do
  describe :having_record_id do
    attr_reader :mill_item, :alma_item

    before(:each) do
      @mill_item = LendingItem.create!(
        barcode: 'C08675309',
        filename: 'b9551212_C08675309',
        title: 'Villette',
        author: 'Brontë, Charlotte',
        millennium_record: 'b9551212',
        alma_record: nil,
        copies: 1
      )
      @alma_item = LendingItem.create!(
        barcode: 'C08675309',
        filename: '012345678987654321_C08675309',
        title: 'Villette',
        author: 'Brontë, Charlotte',
        millennium_record: nil,
        alma_record: '012345678987654321',
        copies: 1
      )
    end

    it 'finds a Millennium item' do
      item = LendingItem.having_record_id(mill_item.millennium_record).take
      expect(item).to eq(mill_item)
    end

    it 'finds an Alma item' do
      item = LendingItem.having_record_id(alma_item.alma_record).take
      expect(item).to eq(alma_item)
    end
  end

  describe :create_iiif_item do
    let(:source_dir) { 'spec/data/lending/incoming/b11996535_fakebarcode' }

    attr_reader :item
    attr_reader :iiif_final_dir

    before(:each) do
      @item = LendingItem.create!(
        barcode: 'fakebarcode',
        filename: 'b11996535_fakebarcode',
        title: 'Pamphlet',
        author: 'Canada. Department of Agriculture.',
        millennium_record: 'b11996535',
        alma_record: nil,
        copies: 1
      )
    end

    describe 'with valid directories' do
      before(:each) do
        @iiif_final_dir = Dir.mktmpdir
        allow(Rails.application.config).to receive(:iiif_source_dir).and_return('spec/data/lending/incoming')
        allow(Rails.application.config).to receive(:iiif_final_dir).and_return(@iiif_final_dir)
      end

      after(:each) do
        FileUtils.rm_rf(@iiif_final_dir)
      end

      it 'tileizes images and copies TXT files' do
        iiif_item = item.create_iiif_item!

        expect(iiif_item).not_to be_nil
        iiif_dir = iiif_item.dir_path
        expect(iiif_dir.parent.to_s).to eq(iiif_final_dir)
        expect(iiif_dir.basename.to_s).to eq(item.filename)

        expect(item.iiif_dir).to eq(iiif_dir.basename.to_s)

        source_entries = Dir.entries(source_dir)
        expected_tiffs = source_entries.select { |e| e.end_with?('.tif') }
        expected_txts = source_entries.select { |e| e.end_with?('.txt') }

        pages = iiif_item.pages
        expect(pages.size).to eq(expected_tiffs.size)
        actual_tiffs = pages.map(&:basename).map(&:to_s)
        actual_texts = pages.map { |p| p.txt_path&.basename&.to_s }

        expect(actual_tiffs).to match_array(expected_tiffs)
        expect(actual_texts).to match_array(expected_txts)
      end
    end

  end
end
