require 'rails_helper'

describe LendingItem, type: :model do
  attr_reader :mill_item, :alma_item, :items

  before(:each) do
    @mill_item = LendingItem.create!(
      directory: 'b155001346_C044219363',
      title: 'Villette',
      author: 'Brontë, Charlotte',
      processed: true,
      copies: 1
    )
    @alma_item = LendingItem.create!(
      directory: '9910661966906531_C044219363',
      title: 'Villette',
      author: 'Brontë, Charlotte',
      processed: true,
      copies: 1
    )
    @items = [mill_item, alma_item]
  end

  describe :available? do
    it 'returns true if there are copies available' do
      items.each do |item|
        expect(item.available?).to eq(true)
      end
    end

    it 'returns false if there are no copies available' do
      items.each do |item|
        item.copies = 0
        expect(item.available?).to eq(false)
      end
    end

    it 'returns false if the item has not been processed' do
      items.each do |item|
        item.processed = false
        expect(item.available?).to eq(false)
      end
    end

    it 'returns false if all copies are checked out' do
      items.each_with_index do |item, i|
        item.check_out_to("patron-#{i}")
        expect(item.available?).to eq(false)
      end
    end
  end

  describe :iiif_item do
    attr_reader :processed, :unprocessed

    before(:each) do
      @processed = items.select(&:processed)
      @unprocessed = items.reject(&:processed)
    end

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
