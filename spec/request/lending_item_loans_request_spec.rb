require 'rails_helper'
require 'calnet_helper'

RSpec.describe '/lending_item_loans', type: :request do

  attr_reader :patron_id, :auth_hash, :user, :lending_item, :valid_attributes, :invalid_attributes

  before(:each) do
    @patron_id = Patron::SAMPLE_IDS[Patron::Type::UNDERGRAD_SLE]
    @auth_hash = auth_hash_for(patron_id)
    @user = User.from_omniauth(auth_hash)

    @lending_item = LendingItem.create!(
      barcode: 'C08675309',
      filename: 'villette.pdf',
      title: 'Villette',
      author: 'Brontë, Charlotte',
      millennium_record: 'b9551212',
      alma_record: nil,
      copies: 1
    )

    @valid_attributes = {
      lending_item_id: lending_item.id,
      patron_identifier: user.uid
    }
  end

  let(:invalid_attributes) do
    {
      lending_item: nil,
      patron_identifier: nil
    }
  end

  describe 'GET /index' do
    it 'renders a successful response' do
      LendingItemLoan.create! valid_attributes
      get lending_item_loans_url
      expect(response).to be_successful
    end
  end

  describe 'GET /show' do
    it 'renders a successful response' do
      lending_item_loan = LendingItemLoan.create! valid_attributes
      get lending_item_loan_url(lending_item_loan)
      expect(response).to be_successful
    end
  end

  describe 'GET /new' do
    it 'renders a successful response' do
      get new_lending_item_loan_url
      expect(response).to be_successful
    end
  end

  describe 'GET /edit' do
    it 'render a successful response' do
      lending_item_loan = LendingItemLoan.create! valid_attributes
      get edit_lending_item_loan_url(lending_item_loan)
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new LendingItemLoan' do
        expect do
          post lending_item_loans_url, params: { lending_item_loan: valid_attributes }
        end.to change(LendingItemLoan, :count).by(1)
      end

      it 'redirects to the created lending_item_loan' do
        post lending_item_loans_url, params: { lending_item_loan: valid_attributes }
        expect(response).to redirect_to(lending_item_loan_url(LendingItemLoan.last))
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new LendingItemLoan' do
        expect do
          post lending_item_loans_url, params: { lending_item_loan: invalid_attributes }
        end.to change(LendingItemLoan, :count).by(0)
      end

      it 'fails with 422 Unprocessable Entity' do
        post lending_item_loans_url, params: { lending_item_loan: invalid_attributes }
        expect(response.status).to eq(422) # unprocessable entity
      end
    end
  end

  describe 'PATCH /update' do
    context 'with valid parameters' do
      let(:new_attributes) do
        # Database loses subsecond precision, so let's lose it first
        # to simplify comparison
        loan_date = Time.now.utc.change(usec: 0)

        { loan_status: 'active', loan_date: loan_date }
      end

      it 'updates the requested lending_item_loan' do
        lending_item_loan = LendingItemLoan.create! valid_attributes
        patch lending_item_loan_url(lending_item_loan), params: { lending_item_loan: new_attributes }
        lending_item_loan.reload
        new_attributes.each do |attr, val|
          expect(lending_item_loan.send(attr)).to eq(val)
        end
      end

      it 'redirects to the lending_item_loan' do
        lending_item_loan = LendingItemLoan.create! valid_attributes
        patch lending_item_loan_url(lending_item_loan), params: { lending_item_loan: new_attributes }
        lending_item_loan.reload
        expect(response).to redirect_to(lending_item_loan_url(lending_item_loan))
      end
    end

    context 'with invalid parameters' do
      it 'fails with 422 Unprocessable Entity' do
        lending_item_loan = LendingItemLoan.create! valid_attributes
        patch lending_item_loan_url(lending_item_loan), params: { lending_item_loan: invalid_attributes }
        expect(response.status).to eq(422) # unprocessable entity
      end
    end
  end

  describe 'DELETE /destroy' do
    it 'destroys the requested lending_item_loan' do
      lending_item_loan = LendingItemLoan.create! valid_attributes
      expect do
        delete lending_item_loan_url(lending_item_loan)
      end.to change(LendingItemLoan, :count).by(-1)
    end

    it 'redirects to the lending_item_loans list' do
      lending_item_loan = LendingItemLoan.create! valid_attributes
      delete lending_item_loan_url(lending_item_loan)
      expect(response).to redirect_to(lending_item_loans_url)
    end
  end
end
