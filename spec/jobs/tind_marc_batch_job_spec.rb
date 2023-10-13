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
    # expect mail.attachments.should have(1).attachment
    # expect { TindMarcBatchJob.perform_now(params) }.to(have { ActionMailer::Base.attachments eq(1) }) 
  end

  describe '#Error perform' do
    it 'raises an error' do
      expect { TindMarcBatchJob.perform_now() }.to raise_error(StandardError)
      # expect { TindMarcBatchJob.perform_now() }.to raise_error(StandardError)
      #allow(TindMarcBatchJob).to receive(:perform_now) { raise StandardError }
      #expect(TindMarcBatchJob.perform_now()).to eq 'error sent email brand'
      #expect(TindMarcBatchJob).to receive(:perform_now).once.and_raise
    end

  end

end
