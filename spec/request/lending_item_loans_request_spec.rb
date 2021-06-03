require 'rails_helper'
require 'calnet_helper'

RSpec.describe '/lending_item_loans', type: :request do

  attr_reader :patron_id, :auth_hash, :user, :lending_item

  before(:each) do
    @patron_id = Patron::Type.sample_id_for(Patron::Type::UNDERGRAD_SLE)
    @user = login_as_patron(patron_id)

    @lending_item = LendingItem.create!(
      barcode: 'C08675309',
      filename: 'villette.pdf',
      title: 'Villette',
      author: 'Brontë, Charlotte',
      millennium_record: 'b9551212',
      alma_record: nil,
      copies: 3
    )
  end

  describe :show do
    it 'shows a loan' do
      loan = LendingItemLoan.check_out(
        lending_item_id: lending_item.id,
        patron_identifier: user.lending_id
      )
      expect(loan).to be_persisted # just to be sure
      get lending_item_loans_path(lending_item_id: lending_item.id)
      expect(response).to be_successful
    end

    it 'returns 404 if no loan exists' do
      get lending_item_loans_path(lending_item_id: lending_item.id)
      expect(response.status).to eq(404)
    end

    it 'pre-returns the loan if already expired' do
      loan_date = Time.now.utc - 3.weeks
      due_date = loan_date + LendingItemLoan::LOAN_DURATION_HOURS.hours
      loan = LendingItemLoan.create(
        lending_item_id: lending_item.id,
        patron_identifier: user.lending_id,
        loan_status: :active,
        loan_date: loan_date,
        due_date: due_date
      )
      get lending_item_loans_path(lending_item_id: lending_item.id)
      expect(response).to be_successful

      loan.reload
      expect(loan.complete?).to eq(true)
      expect(loan.return_date).to be_within(1.minute).of Time.now
    end
  end

  describe :new do
    it 'creates a new, unsaved loan' do
      expect do
        get lending_item_loans_new_path(lending_item_id: lending_item.id)
      end.not_to change(LendingItemLoan, :count)
      expect(response).to be_successful
    end
  end

  describe :check_out do
    it 'checks out an item' do
      expect do
        post lending_item_loans_checkout_path(lending_item_id: lending_item.id)
      end.to change(LendingItemLoan, :count).by(1)

      loan = LendingItemLoan.find_by(
        lending_item_id: lending_item.id,
        patron_identifier: user.lending_id
      )
      expect(loan).to be_active
      expect(loan.loan_date).to be <= Time.now.utc
      expect(loan.due_date).to be > Time.now.utc
      expect(loan.due_date - loan.loan_date).to eq(LendingItemLoan::LOAN_DURATION_HOURS.hours)

      expected_path = lending_item_loans_path(lending_item_id: lending_item.id)
      expect(response).to redirect_to(expected_path)
    end

    it 'fails if this user has already checked out the item' do
      loan = LendingItemLoan.check_out(
        lending_item_id: lending_item.id,
        patron_identifier: user.lending_id
      )
      expect(loan).to be_persisted # just to be sure

      expect do
        post lending_item_loans_checkout_path(lending_item_id: lending_item.id)
      end.not_to change(LendingItemLoan, :count)

      expect(response.status).to eq(422) # unprocessable entity
    end

    it 'fails if there are no copies available' do
      lending_item.copies.times do |copy|
        LendingItemLoan.check_out(
          lending_item_id: lending_item.id,
          patron_identifier: "patron-#{copy}"
        )
      end
      expect(lending_item).not_to be_available # just to be sure

      expect do
        post lending_item_loans_checkout_path(lending_item_id: lending_item.id)
      end.not_to change(LendingItemLoan, :count)

      expect(response.status).to eq(422) # unprocessable entity
    end

  end

  describe :return do
    it 'returns an item' do
      loan = LendingItemLoan.check_out(
        lending_item_id: lending_item.id,
        patron_identifier: user.lending_id
      )
      post lending_item_loans_return_path(lending_item_id: lending_item.id)

      loan.reload
      expect(loan).to be_complete

      expected_path = lending_item_loans_path(lending_item_id: lending_item.id)
      expect(response).to redirect_to(expected_path)
    end

    xit 'does something sensible for duplicate returns'
  end
end
