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
end
