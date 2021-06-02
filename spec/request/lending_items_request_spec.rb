require 'calnet_helper'

RSpec.describe '/lending_items', type: :request do

  # LendingItem. As you add validations to LendingItem, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    {
      barcode: 'C08675309',
      filename: 'villette.pdf',
      title: 'Villette',
      author: 'Brontë, Charlotte',
      millennium_record: 'b9551212',
      alma_record: nil,
      copies: 1
    }
  end

  let(:invalid_attributes) do
    {
      barcode: nil,
      filename: nil,
      title: nil,
      author: nil,
      millennium_record: nil,
      alma_record: nil,
      copies: 1
    }
  end

  after(:each) do
    logout!
  end

  context 'with lending admin privileges' do
    before(:each) do
      mock_calnet_login(CalNet::LENDING_ADMIN_UID)
    end

    describe 'GET /index' do
      it 'renders a successful response' do
        LendingItem.create! valid_attributes
        get lending_items_url
        expect(response).to be_successful
      end
    end

    describe 'GET /show' do
      it 'renders a successful response' do
        lending_item = LendingItem.create! valid_attributes
        get lending_item_url(lending_item)
        expect(response).to be_successful
      end
    end

    describe 'GET /new' do
      it 'renders a successful response' do
        get new_lending_item_url
        expect(response).to be_successful
      end
    end

    describe 'GET /edit' do
      it 'render a successful response' do
        lending_item = LendingItem.create! valid_attributes
        get edit_lending_item_url(lending_item)
        expect(response).to be_successful
      end
    end

    describe 'POST /create' do
      context 'with valid parameters' do
        it 'creates a new LendingItem' do
          expect do
            post lending_items_url, params: { lending_item: valid_attributes }
          end.to change(LendingItem, :count).by(1)
        end

        it 'redirects to the created lending_item' do
          post lending_items_url, params: { lending_item: valid_attributes }
          expect(response).to redirect_to(lending_item_url(LendingItem.last))
        end
      end

      context 'with invalid parameters' do
        it 'does not create a new LendingItem' do
          expect { post lending_items_url, params: { lending_item: invalid_attributes } }
            .to change(LendingItem, :count).by(0)
        end

        it 'fails with 422 Unprocessable Entity' do
          post lending_items_url, params: { lending_item: invalid_attributes }
          expect(response.status).to eq(422) # unprocessable entity
        end
      end
    end

    describe 'PATCH /update' do
      context 'with valid parameters' do
        let(:new_attributes) do
          {
            alma_record: '8675309-5551212',
            copies: 2
          }
        end

        it 'updates the requested lending_item' do
          lending_item = LendingItem.create! valid_attributes
          patch lending_item_url(lending_item), params: { lending_item: new_attributes }
          lending_item.reload
          new_attributes.each { |attr, val| expect(lending_item.send(attr)).to eq(val) }
        end

        it 'redirects to the lending_item' do
          lending_item = LendingItem.create! valid_attributes
          patch lending_item_url(lending_item), params: { lending_item: new_attributes }
          lending_item.reload
          expect(response).to redirect_to(lending_item_url(lending_item))
        end
      end

      context 'with invalid parameters' do
        it 'fails with 422 Unprocessable Entity' do
          lending_item = LendingItem.create! valid_attributes
          patch lending_item_url(lending_item), params: { lending_item: invalid_attributes }
          expect(response.status).to eq(422) # unprocessable entity
        end

        it 'does not modify the original object' do
          lending_item = LendingItem.create! valid_attributes
          patch lending_item_url(lending_item), params: { lending_item: invalid_attributes }

          lending_item.reload
          valid_attributes.each { |attr, val| expect(lending_item.send(attr)).to eq(val) }
        end
      end
    end

    describe 'DELETE /destroy' do
      it 'destroys the requested lending_item' do
        lending_item = LendingItem.create! valid_attributes
        expect do
          delete lending_item_url(lending_item)
        end.to change(LendingItem, :count).by(-1)
      end

      it 'redirects to the lending_items list' do
        lending_item = LendingItem.create! valid_attributes
        delete lending_item_url(lending_item)
        expect(response).to redirect_to(lending_items_url)
      end
    end
  end

  context 'without lending admin privileges' do
    before(:each) do
      patron_id = Patron::Type.sample_id_for(Patron::Type::UNDERGRAD)
      login_as_patron(patron_id)
    end

    describe 'GET /index' do
      it 'returns 403' do
        lending_item = LendingItem.create! valid_attributes
        get lending_item_url(lending_item)
        expect(response.status).to eq(403)
      end
    end

    describe 'GET /new' do
      it 'returns 403' do
        get new_lending_item_url
        expect(response.status).to eq(403)
      end
    end

    describe 'GET /edit' do
      it 'returns 403' do
        lending_item = LendingItem.create! valid_attributes
        get edit_lending_item_url(lending_item)
        expect(response.status).to eq(403)
      end
    end

    describe 'POST /create' do
      it 'returns 403' do
        post lending_items_url, params: { lending_item: valid_attributes }
        expect(response.status).to eq(403)
      end

      it "doesn't create an object" do
        expect { post lending_items_url, params: { lending_item: valid_attributes } }
          .not_to change(LendingItem, :count)
      end
    end

    describe 'PATCH /update' do
      let(:new_attributes) do
        {
          alma_record: '8675309-5551212',
          copies: 2
        }
      end

      it 'returns 403' do
        lending_item = LendingItem.create! valid_attributes
        patch lending_item_url(lending_item), params: { lending_item: new_attributes }
        expect(response.status).to eq(403)
      end

      it "doesn't update the object" do
        lending_item = LendingItem.create! valid_attributes
        patch lending_item_url(lending_item), params: { lending_item: new_attributes }
        lending_item.reload
        valid_attributes.each { |attr, val| expect(lending_item.send(attr)).to eq(val) }
      end
    end

    describe 'DELETE /destroy' do
      it 'returns 403' do
        lending_item = LendingItem.create! valid_attributes
        delete lending_item_url(lending_item)
        expect(response.status).to eq(403)
      end

      it "doesn't delete the object" do
        lending_item = LendingItem.create! valid_attributes
        expect { delete lending_item_url(lending_item) }
          .not_to change(LendingItem, :count)
      end
    end
  end

  context 'without login' do
    xit 'redirects to login'
  end

end
