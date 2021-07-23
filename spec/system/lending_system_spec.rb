require 'capybara_helper'
require 'calnet_helper'

describe LendingController, type: :system do

  # ------------------------------------------------------------
  # Fixture

  before(:each) do
    allow(Rails.application.config).to receive(:iiif_final_dir).and_return('spec/data/lending/samples/final')
  end

  let(:valid_item_attributes) do
    [
      {
        title: 'The Plan of St. Gall : a study of the architecture & economy of life in a paradigmatic Carolingian monastery',
        author: 'Horn, Walter',
        directory: 'b100523250_C044235662',
        copies: 1,
        active: true
      },
      {
        title: 'The great depression in Europe, 1929-1939',
        author: 'Clavin, Patricia.',
        directory: 'b135297126_C068087930',
        copies: 0,
        active: false
      },
      {
        title: 'Villette',
        author: 'Brontë, Charlotte',
        directory: 'b155001346_C044219363',
        copies: 0,
        active: false
      },
      {
        title: 'Pamhlet.',
        author: 'Canada. Department of Agriculture.',
        directory: 'b11996535_B 3 106 704',
        copies: 0,
        active: false
      }
    ]
  end

  attr_reader :items
  attr_reader :item

  def processed
    items.select(&:processed?)
  end

  def invalid
    items.reject(&:processed?)
  end

  def active
    processed.select(&:active?)
  end

  def inactive
    processed.reject(&:active?)
  end

  after(:each) { logout! }

  # ------------------------------------------------------------
  # Tests

  context 'as lending admin' do
    before(:each) { mock_calnet_login(CalNet::LENDING_ADMIN_UID) }

    context 'without any items' do
      describe :index do
        it 'shows an empty list' do
          visit lending_path

          expect(page.title).to include('UC BEARS')
          expect(page).not_to have_xpath("//div[contains(@class, 'alerts')]")
        end
      end
    end

    context 'with items' do
      before(:each) do
        @items = valid_item_attributes.map do |item_attributes|
          LendingItem.create!(**item_attributes)
        end
        @item = items.first
      end

      describe :index do
        before(:each) do
          visit lending_path
        end

        it 'lists the items' do
          expect(page.title).to include('UC BEARS')
          expect(page).not_to have_xpath("//div[contains(@class, 'alerts')]")

          aggregate_failures :items do
            items.each do |item|
              expect(page).to have_content(item.title)
            end
          end
        end

        it 'categorizes the items by state' do
          states = %i[active inactive invalid]

          states.each do |state|
            expect(page).to have_xpath("//h2[@id='#{state}']"), "No <h2> found for state #{state}"
          end

          tables_by_state = states.map do |state|
            [state, find(:xpath, "//table[@id='lending-#{state}']")]
          end.to_h

          states.each do |state|
            items_for_state = send(state)
            expect(items_for_state).not_to be_empty, "No items for state #{state}"

            table = tables_by_state[state]
            item_rows = table.all(:xpath, ".//tr[@class='item-row']")
            row_count = item_rows.size
            item_count = items_for_state.size
            expect(row_count).to eq(item_count), "Expected #{item_count} rows for #{state}, got #{row_count}: #{item_rows.map(&:text).join(', ')}"

            items_for_state.each do |item|
              item_row = table.find(:xpath, ".//tr[td[contains(text(), '#{item.title}')]]")
              show_path = lending_show_path(directory: item.directory)
              # show_link = item_row.find_link('Show', href: /#{Regexp.escape(show_path)}/)
              expect(item_row).to have_link('Show', href: /#{Regexp.escape(show_path)}/)
            end
          end
        end
      end
    end
  end
end
