require 'capybara_helper'
require 'calnet_helper'

describe LendingController, type: :system do

  # ------------------------------------------------------------
  # Fixture

  let(:states) { %i[active inactive incomplete] }

  let(:valid_item_attributes) do
    [
      {
        title: 'The Plan of St. Gall : a study of the architecture & economy of life in a paradigmatic Carolingian monastery',
        author: 'Horn, Walter',
        directory: 'b100523250_C044235662',
        copies: 3,
        active: true
      },
      {
        title: 'The great depression in Europe, 1929-1939',
        author: 'Clavin, Patricia.',
        directory: 'b135297126_C068087930',
        copies: 1,
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
        title: 'Pamphlet.',
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
    items.select(&:complete?)
  end

  def incomplete
    items.reject(&:complete?)
  end

  def active
    processed.select(&:active?)
  end

  def inactive
    processed.reject(&:active?)
  end

  before(:each) do
    allow(Rails.application.config).to receive(:iiif_final_dir).and_return('spec/data/lending/samples/final')
  end

  after(:each) do
    clear_login_state!
  end

  # ------------------------------------------------------------
  # Helper methods

  def expect_no_alerts
    expect(page).not_to have_xpath("//div[contains(@class, 'alerts')]")
  end

  # ------------------------------------------------------------
  # Tests

  context 'as lending admin' do
    before(:each) { mock_calnet_login(CalNet::LENDING_ADMIN_UID) }

    context 'without any items' do
      describe :index do
        it 'shows an empty list' do
          visit lending_path

          expect(page.title).to include('UC BEARS')
          expect_no_alerts
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
          expect_no_alerts

          aggregate_failures :items do
            items.each do |item|
              expect(page).to have_content(item.title)
            end
          end
        end

        it 'categorizes the items by state' do
          states.each do |state|
            expect(page).to have_xpath("//h2[@id='#{state}']"), "No <h2> found for state #{state}"
          end

          tables_by_state = states.map do |state|
            [state, find(:xpath, "//table[@id='lending-#{state}']")]
          end.to_h

          states.each do |state|
            items_for_state = send(state)
            expect(items_for_state).not_to be_empty, "No items for state #{state}" # just to be sure

            table = tables_by_state[state]
            item_rows = table.all(:xpath, ".//tr[@class='item-row']")
            row_count = item_rows.size
            item_count = items_for_state.size
            expect(row_count).to eq(item_count), "Expected #{item_count} rows for #{state}, got #{row_count}: #{item_rows.map(&:text).join(', ')}"

            items_for_state.each do |item|
              item_row = table.find(:xpath, ".//tr[td[contains(text(), '#{item.title}')]]")
              show_path = lending_show_path(directory: item.directory)
              expect(item_row).to have_link('Show', href: /#{Regexp.escape(show_path)}/)
            end
          end
        end

        it 'has show and edit buttons for all items' do
          items.each do |item|
            item_row = find(:xpath, "//tr[td[contains(text(), '#{item.title}')]]")
            show_path = lending_show_path(directory: item.directory)
            show_link = item_row.find_link('Show')
            expect(URI.parse(show_link['href']).path).to eq(show_path)

            edit_path = lending_edit_path(directory: item.directory)
            edit_link = item_row.find_link('Edit')
            expect(URI.parse(edit_link['href']).path).to eq(edit_path)
          end
        end

        it 'has "make active" only for processed, inactive items with copies' do
          items.each do |item|
            item_row = find(:xpath, "//tr[td[contains(text(), '#{item.title}')]]")
            activate_path = lending_activate_path(directory: item.directory)

            if item.active? || item.incomplete?
              expect(item_row).not_to have_link('Make Active')
            else
              activate_link = item_row.find_link('Make Active')
              if item.copies > 0
                expect(URI.parse(activate_link['href']).path).to eq(activate_path)
              else
                expect(activate_link['href']).to be_nil
                expect(activate_link['class']).to include('disabled')
              end
            end
          end
        end

        it 'has "make inactive" only for processed, active items' do
          items.each do |item|
            item_row = find(:xpath, "//tr[td[contains(text(), '#{item.title}')]]")
            deactivate_path = lending_deactivate_path(directory: item.directory)
            if item.incomplete? || !item.active?
              expect(item_row).not_to have_link('Make Inactive')
            else
              link = item_row.find_link('Make Inactive')
              expect(URI.parse(link['href']).path).to eq(deactivate_path)
            end
          end
        end

        it 'has "delete" only for incomplete items' do
          items.each do |item|
            item_row = find(:xpath, "//tr[td[contains(text(), '#{item.title}')]]")
            delete_path = lending_destroy_path(directory: item.directory)
            if item.incomplete?
              delete_form = item_row.find(:xpath, ".//form[@action='#{delete_path}']")
              expect(delete_form).to have_button('Delete')
            else
              expect(item_row).not_to have_xpath(".//form[@action='#{delete_path}']")
              expect(item_row).not_to have_button('Delete')
            end
          end
        end

        describe 'Show' do
          it 'shows the item preview' do
            item = items.first
            item_row = find(:xpath, "//tr[td[contains(text(), '#{item.title}')]]")

            show_path = lending_show_path(directory: item.directory)
            show_link = item_row.find_link('Show')
            expect(URI.parse(show_link['href']).path).to eq(show_path)
            show_link.click

            expect_no_alerts
            expect(page).to have_current_path(show_path)
          end
        end

        describe 'Edit' do
          it 'shows the edit screen' do
            item = items.first
            item_row = find(:xpath, "//tr[td[contains(text(), '#{item.title}')]]")

            edit_path = lending_edit_path(directory: item.directory)
            edit_link = item_row.find_link('Edit')
            expect(URI.parse(edit_link['href']).path).to eq(edit_path)
            edit_link.click

            expect_no_alerts
            expect(page).to have_current_path(edit_path)
          end
        end

        describe 'Make Active' do
          it 'activates an item' do
            item = inactive.find { |it| it.copies > 0 }
            item_row = find(:xpath, "//tr[td[contains(text(), '#{item.title}')]]")

            activate_path = lending_activate_path(directory: item.directory)
            activate_link = item_row.find_link('Make Active')
            expect(URI.parse(activate_link['href']).path).to eq(activate_path)
            activate_link.click

            active_table = find(:xpath, "//table[@id='lending-active']")
            expect(active_table).to have_xpath(".//tr[td[contains(text(), '#{item.title}')]]")

            alert = page.find('.alert-success')
            expect(alert).to have_text('Item now active.')

            item.reload
            expect(item).to be_active
          end
        end
      end

      describe :show do
        it 'displays all due dates' do
          item = active.find { |it| it.copies > 1 }
          loans = item.copies.times.with_object([]) do |i, ll|
            loan = item.check_out_to!("patron-#{i}")
            loan.due_date = loan.due_date + i.days # just to differentiate
            loan.save!
            ll << loan
          end

          visit lending_show_path(directory: item.directory)

          loans.each do |loan|
            expect(page).to have_content(loan.due_date.to_s(:short))
          end
        end
      end
    end
  end

  context 'as patron' do
    attr_reader :user, :item

    before(:each) do
      patron_id = Patron::Type.sample_id_for(Patron::Type::UNDERGRAD)
      @user = login_as_patron(patron_id)
      @items = valid_item_attributes.map do |item_attributes|
        LendingItem.create!(**item_attributes)
      end
      @item = items.find(&:available?)
    end

    describe :view do
      it 'allows a checkout' do
        expect(item).to be_available # just to be sure
        expect(LendingItemLoan.where(patron_identifier: user.lending_id)).not_to exist # just to be sure

        visit lending_view_path(directory: item.directory)
        expect(page).not_to have_selector('div#iiif_viewer')

        checkout_path = lending_check_out_path(directory: item.directory)
        checkout_link = page.find_link('Check out')
        expect(URI.parse(checkout_link['href']).path).to eq(checkout_path)
        checkout_link.click

        alert = page.find('.alert-success')
        expect(alert).to have_text('Checkout successful.')

        expect(page).to have_selector('div#iiif_viewer')
      end

      it 'allows a return' do
        item.check_out_to(user.lending_id)

        visit lending_view_path(directory: item.directory)

        return_path = lending_return_path(directory: item.directory)
        return_link = page.find_link('Return now')
        expect(URI.parse(return_link['href']).path).to eq(return_path)
        return_link.click

        alert = page.find('.alert-success')
        expect(alert).to have_text('Item returned.')

        expect(page).not_to have_selector('div#iiif_viewer')
      end
    end
  end
end
