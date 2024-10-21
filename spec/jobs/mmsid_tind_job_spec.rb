require 'support/tind_marc_contexts'
require 'jobs_helper'

describe MmsidTindJob do

  describe '#MmsidTindJob: directory batch, normal labels.csv file, with append tind_mmsid info' do
    include_context 'setup_with_args_and_tind_request', :directory_batch_path

    it 'job completed and email sent out' do
      expect { MmsidTindJob.perform_now(args, email) }.to(change { ActionMailer::Base.deliveries.count })
    end
  end

end
