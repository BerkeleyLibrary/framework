require 'rails_helper'
require 'calnet_helper'

RSpec.describe LendingItemLoansController, type: :request do

  context 'with login' do
    attr_reader :patron_id, :auth_hash, :user, :lending_item

    before(:each) do
      @patron_id = Patron::Type.sample_id_for(Patron::Type::UNDERGRAD_SLE)
      @user = login_as_patron(patron_id)

      @lending_item = LendingItem.create!(
        author: 'Clavin, Patricia',
        title: 'The Great Depression in Europe, 1929-1939',
        directory: 'b135297126_C068087930',
        copies: 2,
        processed: true
      )
    end

    describe :show do
      it 'creates a new, unsaved loan if none exists' do
        expect do
          get lending_item_loans_path(lending_item_id: lending_item.id)
        end.not_to change(LendingItemLoan, :count)
        expect(response).to be_successful
      end

      it 'shows a loan' do
        loan = lending_item.check_out_to(user.lending_id)
        expect(loan.errors.full_messages).to be_empty
        expect(loan).to be_persisted # just to be sure
        get lending_item_loans_path(lending_item_id: lending_item.id)
        expect(response).to be_successful
      end

      it 'pre-returns the loan if already expired' do
        loan_date = Time.now.utc - 3.weeks
        due_date = loan_date + LendingItem::LOAN_DURATION_HOURS.hours
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

      it 'displays an item with no available copies' do
        lending_item.copies.times do |copy|
          lending_item.check_out_to("patron-#{copy}")
        end
        expect(lending_item).not_to be_available # just to be sure

        get lending_item_loans_path(lending_item_id: lending_item.id)
        expect(response).to be_successful
        expect(response.body).to include(LendingItem::MSG_UNAVAILABLE)

        # TODO: format all dates
        due_date_str = lending_item.next_due_date.to_s
        expect(response.body).to include(due_date_str)
      end

      it 'displays an item that has not yet been processed' do
        lending_item.processed = false
        lending_item.save!
        expect(lending_item).not_to be_processed # just to be sure

        get lending_item_loans_path(lending_item_id: lending_item.id)
        expect(response).to be_successful
        expect(response.body).to include(LendingItem::MSG_UNPROCESSED)
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
        expect(loan.due_date - loan.loan_date).to eq(LendingItem::LOAN_DURATION_HOURS.hours)

        expected_path = lending_item_loans_path(lending_item_id: lending_item.id)
        expect(response).to redirect_to(expected_path)
      end

      it 'fails if this user has already checked out the item' do
        loan = lending_item.check_out_to(user.lending_id)
        expect(loan).to be_persisted # just to be sure

        expect do
          post lending_item_loans_checkout_path(lending_item_id: lending_item.id)
        end.not_to change(LendingItemLoan, :count)

        expect(response.status).to eq(422) # unprocessable entity
      end

      it 'fails if there are no copies available' do
        lending_item.copies.times do |copy|
          lending_item.check_out_to("patron-#{copy}")
        end
        expect(lending_item).not_to be_available # just to be sure

        expect do
          post lending_item_loans_checkout_path(lending_item_id: lending_item.id)
        end.not_to change(LendingItemLoan, :count)

        expect(response.status).to eq(422) # unprocessable entity
      end

      it 'fails if the item has not been processed' do
        lending_item.processed = false
        lending_item.save!
        expect(lending_item).not_to be_processed # just to be sure

        expect do
          post lending_item_loans_checkout_path(lending_item_id: lending_item.id)
        end.not_to change(LendingItemLoan, :count)

        expect(response.status).to eq(422)
        expect(response.body).to include(LendingItem::MSG_UNPROCESSED)
      end
    end

    describe :return do
      it 'returns an item' do
        loan = lending_item.check_out_to(user.lending_id)
        post lending_item_loans_return_path(lending_item_id: lending_item.id)

        loan.reload
        expect(loan).to be_complete

        expected_path = lending_item_loans_path(lending_item_id: lending_item.id)
        expect(response).to redirect_to(expected_path)
      end

      it 'succeeds even if the item was already returned' do
        loan = lending_item.check_out_to(user.lending_id)
        loan.return!

        post lending_item_loans_return_path(lending_item_id: lending_item.id)
        expected_path = lending_item_loans_path(lending_item_id: lending_item.id)
        expect(response).to redirect_to(expected_path)
      end

      it 'succeeds even if the item was never checked out' do
        expect { post lending_item_loans_return_path(lending_item_id: lending_item.id) }.not_to change(LendingItemLoan, :count)
        expected_path = lending_item_loans_path(lending_item_id: lending_item.id)
        expect(response).to redirect_to(expected_path)
      end
    end
  end

  context 'without login' do
    xit 'redirects to login'
  end
end
