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
end
