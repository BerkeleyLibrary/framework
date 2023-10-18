require 'json'
require 'jobs_helper'

describe TindMarcBatchJob do

  params = { directory: 'somewhere', resource_type: 'Image',
             library: 'The Bancroft Library', f_540_a: 'some rights statement',
             f_980_a: 'map field 980a', f_982_a: 'short collection name',
             f_982_b: 'long collection name', f_982_p: 'larger project',
             restriction: 'Restricted2Bancroft', email: 'some_email@nowhere.com' }

  it 'executes tind marc batch job and sends an email' do
    expect { TindMarcBatchJob.perform_now(params) }.to(change { ActionMailer::Base.deliveries.count })
  end

  describe '#Error perform' do
    it 'raises an error' do
      allow(TindMarcBatch).to receive(:perform_later).with(params).and_return{ StandardError }
      expect(TindMarcBatch.perform_later).to eq StandardError
    end

  end

end
