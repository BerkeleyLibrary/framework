require 'rails_helper'

module TindMarc
  RSpec.describe BatchCreator do
    params = { directory: 'somewhere', resource_type: 'Image', library: 'The Bancroft Library', f_540_a: 'some rights statement', f_980_a: 'map field 980a', f_982_a: 'short collection name', f_982_b: 'long collection name', f_982_p: 'larger project', restriction: 'Restricted2Bancroft', email: 'some_email@nowhere.com' }
   
    let(:marc_batch) { TindMarc::BatchCreator.new(params) }

    it 'was instantiated and can call methods' do
     expect(marc_batch).to respond_to(:prepare)
     expect(marc_batch).to respond_to(:produce_marc)
     expect(marc_batch).to respond_to(:send_email)
    end
    
  end
end
