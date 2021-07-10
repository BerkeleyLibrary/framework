require 'rails_helper'

describe LendingItem, type: :model do
  attr_reader :items, :processed, :unprocessed

  context 'without existing items' do
    describe :scan_for_new_items! do
      it 'creates new items' do
        items = LendingItem.scan_for_new_items!
        expected_dirs = Pathname.new(LendingItem.iiif_final_root).children.select { |d| Lending::PathUtils.item_dir?(d) }
        expect(items.size).to eq(expected_dirs.size)
      end
    end
  end

  context 'with existing items' do

    before(:each) do
      @items = [
        {
          title: 'Villette',
          author: 'Brontë, Charlotte',
          directory: 'b155001346_C044219363',
          copies: 1
        },
        {
          title: 'The Great Depression in Europe, 1929-1939',
          author: 'Clavin, Patricia',
          directory: 'b135297126_C068087930',
          copies: 3
        },
        {
          title: 'The Plan of St. Gall',
          author: 'Horn, Walter',
          directory: 'b100523250_C044235662',
          copies: 6
        },
        {
          title: 'Pamphlet',
          author: 'Canada. Department of Agriculture.',
          directory: 'b11996535_B 3 106 704',
          copies: 2
        }
      ].map { |item_attributes| LendingItem.create!(**item_attributes) }

      @processed = items.select(&:processed?)
      @unprocessed = items.reject(&:processed?)
    end

    describe :iiif_dir? do
      it 'returns true for items with populated image directories' do
        items.each do |item|
          iiif_dir = item.iiif_dir
          expected = File.directory?(iiif_dir) && !Dir.empty?(iiif_dir)
          expect(item.iiif_dir?).to eq(expected)
        end
      end
    end

    describe :processed? do
      it 'returns true only items with manifest templates and populated image directories' do
        items.each do |item|
          expected = item.iiif_dir? && item.iiif_manifest.has_template?
          expect(item.processed?).to eq(expected)
        end
        expect(processed).not_to be_empty
      end
    end

    describe :available? do
      it 'returns true if there are copies available' do
        processed.each do |item|
          expect(item.available?).to eq(true)
        end
      end

      it 'returns false if there are no copies available' do
        processed.each do |item|
          item.copies = 0
          expect(item.available?).to eq(false)
        end
      end

      it 'returns false if the item has not been processed' do
        unprocessed.each do |item|
          expect(item.available?).to eq(false)
        end
      end

      it 'returns false if all copies are checked out' do
        processed.each do |item|
          item.copies.times { |i| item.check_out_to("patron-#{i}") }
          expect(item.available?).to eq(false)
        end
      end
    end

    describe :iiif_manifest do
      it 'returns the IIIFItem if the item has been processed' do
        processed.each do |item|
          iiif_item = item.iiif_manifest
          expect(iiif_item).to be_a(Lending::IIIFManifest)
          expect(iiif_item.title).to eq(item.title)
          expect(iiif_item.author).to eq(item.author)
          expect(iiif_item.dir_path.to_s).to eq(item.iiif_dir)
        end
      end

      it 'raises RecordNotFound if the item has not been processed' do
        unprocessed.each do |item|
          expect { item.iiif_manifest }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

  end
end
