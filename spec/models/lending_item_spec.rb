require 'rails_helper'

describe LendingItem, type: :model do
  attr_reader :items, :processed, :unprocessed

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
        title: 'Pamphlet',
        author: 'Canada. Department of Agriculture.',
        directory: 'b11996535_B 3 106 704',
        copies: 2
      }
    ].map { |item_attributes| LendingItem.create!(**item_attributes) }

    @processed = items.select(&:processed?)
    @unprocessed = items.reject(&:processed?)
  end

  describe :processed? do
    it 'returns true for items with populated image directories' do
      expect(processed).not_to be_empty
      processed.each do |item|
        iiif_dir = item.iiif_dir
        expect(File.directory?(iiif_dir)).to eq(true)
        expect(Dir.empty?(iiif_dir)).to eq(false)
      end
    end

    it 'returns false for items without populated image directories' do
      expect(unprocessed).not_to be_empty
      unprocessed.each do |item|
        iiif_dir = item.iiif_dir
        expect(Dir.empty?(iiif_dir)).to eq(true) if File.exist?(iiif_dir)
      end
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

  describe :iiif_item do
    it 'returns the IIIFItem if the item has been processed' do
      processed.each do |item|
        iiif_item = item.iiif_item
        expect(iiif_item).to be_a(Lending::IIIFItem)
        expect(iiif_item.title).to eq(item.title)
        expect(iiif_item.author).to eq(item.author)
        expect(iiif_item.dir_path.to_s).to eq(item.iiif_dir)
      end
    end

    it 'raises RecordNotFound if the item has not been processed' do
      unprocessed.each do |item|
        expect { item.iiif_item }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
