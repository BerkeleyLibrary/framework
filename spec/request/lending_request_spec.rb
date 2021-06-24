require 'calnet_helper'

describe LendingController, type: :request do
  let(:valid_item_attributes) do
    [
      {
        title: 'Villette',
        author: 'Brontë, Charlotte',
        directory: 'b155001346_C044219363',
        processed: true,
        copies: 1
      },
      {
        title: 'Pamphlet',
        author: 'Canada. Department of Agriculture.',
        directory: 'b11996535_B 3 106 704',
        copies: 0
      },
      {
        title: 'The Great Depression in Europe, 1929-1939',
        author: 'Clavin, Patricia',
        directory: 'b135297126_C068087930',
        copies: 2,
        processed: true
      }
    ]
  end

  attr_reader :items

  after(:each) { logout! }

  context 'as lending admin' do
    before(:each) { mock_calnet_login(CalNet::LENDING_ADMIN_UID) }

    context 'without any items' do
      describe :index do
        it 'shows an empty list' do
          get lending_url
          expect(response).to be_successful
        end
      end

      describe :create do
        it 'creates items' do
          valid_item_attributes.each do |item_attributes|
            expect do
              post lending_url, attributes: { lending_item: item_attributes }
            end.to change(LendingItem, :count).by(1)

            directory = item_attributes[:directory]
            item = LendingItem.find_by(directory: directory)
            expect(item).not_to be_nil

            item_attributes.each do |attr, val|
              expect(item.send(attr)).to eq(val)
              expect(item.copies_available).to eq(item.copies)
            end
          end
        end

        describe 'with invalid attributes' do
          let(:invalid_item_attributes) do
            valid_attributes = valid_item_attributes[0]
            [].tap do |invalid_item_attributes|
              [:directory, :title, :author].each do |attr|
                invalid_attributes = valid_attributes.dup
                invalid_attributes.delete(attr)
                invalid_item_attributes << invalid_attributes
              end

              invalid_attributes = valid_attributes.dup
              invalid_attributes.copies = -1
              invalid_item_attributes << invalid_attributes
            end
          end

          it 'does not create items' do
            invalid_item_attributes.each do |item_attributes|
              expect { post lending_url, attributes: { lending_item: item_attributes } }
                .not_to change(LendingItem, :count)
              expect(response.status).to eq(422) # unprocessable entity
            end
          end
        end
      end
    end

    context 'with items' do
      before(:each) do
        @items = valid_item_attributes.map do |item_attributes|
          LendingItem.create!(**item_attributes)
        end
      end

      describe :index do
        it 'lists the items' do
          get lending_url
          expect(response).to be_successful

          body = response.body
          items.each do |item|
            expect(body).to include(item.title)
            expect(body).to include(item.author)
            expect(body).to include(item.directory)
          end
        end
      end

      describe :show do
        it 'shows an item' do
          items.each do |item|
            get lending_show_url(directory: item.directory)
            expect(response).to be_successful
          end
        end
      end

      describe :manifest do
        it 'shows the manifest for processed items' do
          items.select(&:processed?).each do |item|
            get lending_manifest_url(directory: item.directory)
            expect(response).to be_successful

            # TODO: validate manifest contents
          end
        end
      end

      describe :update do
        let(:new_attributes) do
          {
            copies: 2,
            processed: true
          }
        end

        it 'updates an item' do
          items.each do |item|
            directory = item.directory

            expect do
              patch lending_url(attributes: { directory: directory, lending_item: new_attributes })
            end.not_to change(LendingItem, :count)

            expect(response).to redirect_to lending_url(directory: directory)

            item.reload
            new_attributes.each { |attr, val| expect(item.send(attr)).to eq(val) }
          end
        end
      end
    end
  end

  describe 'with patron credentials' do
    attr_reader :user, :item

    before(:each) do
      patron_id = Patron::Type.sample_id_for(Patron::Type::UNDERGRAD_SLE)
      @user = login_as_patron(patron_id)
      @item = LendingItem.create(**valid_item_attributes.last)
    end

    describe :show do
      it "doesn't create a new loan record" do
        expect do
          get lending_show_url(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)
        expect(response).to be_successful
        expect(response.body).to include('Check out')
        expect(response.body).not_to include('Return')
      end

      it 'shows a loan if one exists' do
        loan = item.check_out_to(user.lending_id)
        expect(loan.errors.full_messages).to be_empty
        expect(loan).to be_persisted # just to be sure

        expect do
          get lending_show_url(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)
        expect(response).to be_successful

        body = response.body

        # TODO: format all dates
        due_date_str = item.next_due_date.to_s
        expect(body).to include(due_date_str)

        expect(body).not_to include('Check out')
        expect(body).to include('Return')
      end

      it 'pre-returns the loan if already expired' do
        loan_date = Time.now.utc - 3.weeks
        due_date = loan_date + LendingItem::LOAN_DURATION_HOURS.hours
        loan = LendingItemLoan.create(
          lending_item_id: item.id,
          patron_identifier: user.lending_id,
          loan_status: :active,
          loan_date: loan_date,
          due_date: due_date
        )

        expect do
          get lending_show_url(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)
        expect(response).to be_successful

        loan.reload
        expect(loan).to be_complete
        expect(loan.return_date).to be_within(1.minute).of Time.now

        body = response.body

        # TODO: format all dates
        return_date_str = loan.return_date
        expect(body).to include(return_date_str)

        expect(body).to include('Check out')
        expect(body).not_to include('Return')
      end

      it 'displays an item with no available copies' do
        item.copies.times do |copy|
          item.check_out_to("patron-#{copy}")
        end
        expect(item).not_to be_available # just to be sure

        expect do
          get lending_show_url(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)
        expect(response).to be_successful

        body = response.body
        expect(body).not_to include('Check out')
        expect(body).not_to include('Return')
        expect(body).to include(LendingItem::MSG_UNAVAILABLE)

        # TODO: format all dates
        due_date_str = item.next_due_date.to_s
        expect(body).to include(due_date_str)
      end

      it 'displays an item that has not yet been processed' do
        item.processed = false
        item.save!

        expect do
          get lending_show_url(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)
        expect(response).to be_successful

        body = response.body
        expect(body).not_to include('Check out')
        expect(body).not_to include('Return')
        expect(body).to include(LendingItem::MSG_UNPROCESSED)
      end
    end

    describe :check_out do
      it 'checks out an item' do
        expect do
          post lending_check_out(directory: item.directory)
        end.to change(LendingItemLoan, :count).by(1)

        loan = LendingItemLoan.find_by(
          lending_item_id: lending_item.id,
          patron_identifier: user.lending_id
        )
        expect(loan).to be_active
        expect(loan.loan_date).to be <= Time.now.utc
        expect(loan.due_date).to be > Time.now.utc
        expect(loan.due_date - loan.loan_date).to eq(LendingItem::LOAN_DURATION_HOURS.hours)

        expected_path = lending_show_path(directory: item.directory)
        expect(response).to redirect_to(expected_path)
      end

      it 'fails if this user has already checked out the item' do
        loan = item.check_out_to(user.lending_id)
        expect(loan).to be_persisted

        expect do
          post lending_check_out(directory: item.directory)
        end.not_to change(LendingItemLoan, :count).by(1)

        expect(response.status).to eq(422) # unprocessable entity
        expect(reponse.body).to include(LendingItem::MSG_CHECKED_OUT)
      end

      it 'fails if there are no copies available' do
        item.copies.times do |copy|
          item.check_out_to("patron-#{copy}")
        end
        expect(item).not_to be_available

        expect do
          post lending_check_out(directory: item.directory)
        end.not_to change(LendingItemLoan, :count).by(1)

        expect(response.status).to eq(422) # unprocessable entity
        expect(reponse.body).to include(LendingItem::MSG_UNAVAILABLE)
      end

      it 'fails if the item has not been processed' do
        item.processed = false
        item.save!
        expect(item).not_to be_processed # just to be sure

        expect do
          post lending_check_out(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)

        expect(response.status).to eq(422)
        expect(response.body).to include(LendingItem::MSG_UNPROCESSED)
      end
    end

    describe :return do
      it 'returns an item' do
        loan = item.check_out_to(user.lending_id)
        post lending_return_path(directory: item.directory)

        loan.reload
        expect(loan).to be_complete

        expected_path = lending_show_path(directory: item.directory)
        expect(response).to redirect_to(expected_path)
      end

      it 'succeeds even if the item was already returned' do
        loan = item.check_out_to(user.lending_id)
        loan.return!

        post lending_return_path(directory: item.directory)
        expected_path = lending_show_path(directory: item.directory)
        expect(response).to redirect_to(expected_path)
      end

      it 'succeeds even if the item was never checked out' do
        expect do
          post lending_return_path(directory: item.directory)
        end.not_to change(LendingItemLoan, :count)
        expected_path = lending_show_path(directory: item.directory)
        expect(response).to redirect_to(expected_path)
      end
    end
  end

  describe 'without login' do
    xit 'redirects to login'
  end

  describe 'with ineligible patron' do
    xit 'displays unauthorized'
  end
end
