require 'capybara_helper'

describe 'browser visibility', type: :system do
  before { visit root_path }

  it 'reloads an element when Chrome reports that it belongs to the previous document' do
    element = find('html')
    error = Selenium::WebDriver::Error::UnknownError.new('Node with given id does not belong to the document')
    allow(element.native).to receive(:displayed?).and_raise(error)

    expect(element).to be_visible
  end

  it 'propagates unrelated browser errors' do
    element = find('html')
    error = Selenium::WebDriver::Error::UnknownError.new('browser connection failed')
    allow(element.native).to receive(:displayed?).and_raise(error)

    expect { element.visible? }.to raise_error(error)
  end
end
