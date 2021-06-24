require 'calnet_helper'

describe LendingController, type: :request do
  let(:valid_item_params) do
    [
      {
        title: 'Villette',
        author: 'Brontë, Charlotte',
        directory: 'b155001346_C044219363',
        processed: true,
        copies: 1
      },
      {
        title: 'The Great Depression in Europe, 1929-1939',
        author: 'Clavin, Patricia',
        directory: 'b135297126_C068087930',
        copies: 2,
        processed: true
      },
      {
        title: 'Pamphlet',
        author: 'Canada. Department of Agriculture.',
        directory: 'b11996535_B 3 106 704',
        copies: 0
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
          valid_item_params.each do |item_params|
            expect do
              post lending_create_url, params: { lending_item: item_params }
            end.to change(LendingItem, :count).by(1)

            directory = item_params[:directory]
            item = LendingItem.find_by(directory: directory)
            expect(item).not_to be_nil

            item_params.each do |attr, val|
              expect(item.send(attr)).to eq(val)
              expect(item.copies_available).to eq(item.copies)
            end
          end
        end
      end
    end

    context 'with items' do
      before(:each) do
        @items = valid_item_params.map do |item_params|
          LendingItem.create!(**item_params)
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
    end

  end
end
