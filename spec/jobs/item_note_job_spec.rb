require 'json'
require 'jobs_helper'

describe ItemNoteJob do
  let(:alma_api_key) { 'totally-fake-key' }

  it 'executes item note job and send an email' do
    stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/sets/123/members?offset=0').to_return(
      status: 200,
      body: File.new('spec/data/alma_items/item_members_1.json')
    )

    stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/2222/holdings/22667730250006532/items/3333').to_return(
      status: 200,
      body: File.new('spec/data/alma_items/item_bibdata_1.json')
    )

    stub_request(:put, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/2222/holdings/22667730250006532/items/3333')
      .with(
        body: File.read('spec/data/alma_items/item_update_1.txt')
      )
      .to_return(
        status: 200
      )

    expect { ItemNoteJob.perform_now('sandbox', '123', 'Fake Note', '1', 'fake@email.com') }.to(change { ActionMailer::Base.deliveries.count })
  end
end
