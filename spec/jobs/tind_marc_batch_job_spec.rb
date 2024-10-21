require 'support/tind_marc_contexts'
require 'jobs_helper'

describe TindMarcBatchJob do

  describe '#TindMarcBatchSecondJob: directory batch, normal labels.csv file, with append tind_mmsid info' do
    include_context 'setup_with_args_and_alma_request', :directory_batch_path, 'normal', 'with_append'

    it 'job completed and email sent out' do
      expect { TindMarcBatchJob.perform_now(args, email) }.to(change { ActionMailer::Base.deliveries.count })
    end
  end

end
