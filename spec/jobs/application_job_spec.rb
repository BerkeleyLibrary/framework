require 'rails_helper'

class TestJob < ApplicationJob
  def perform(*args); end
end

RSpec.describe ApplicationJob, type: :job do
  include ActiveJob::TestHelper

  after do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  describe 'jobs with request_id' do
    let(:request_id) { SecureRandom.uuid }

    context 'when Current.request_id is set' do
      before do
        allow(Current).to receive(:request_id).and_return(request_id)
      end

      it 'enqueues the job with the request_id' do
        expect do
          TestJob.perform_later('some_arg')
        end.to have_enqueued_job(TestJob)

        enqueued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
        expect(enqueued_job[:args]).to eq(['some_arg'])
        expect(enqueued_job['request_id']).to eq(request_id)
      end

      it 'logs the activejob_id and request_id' do
        job = TestJob.new('some_arg')
        allow(job.logger).to receive(:with_fields=)

        perform_enqueued_jobs { job.perform_now }

        expect(job.logger).to have_received(:with_fields=).with(hash_including(activejob_id: job.job_id, request_id: request_id))
      end
    end
  end

  describe 'jobs without a request_id' do
    context 'when Current.request_id is not set' do
      it 'enqueues the job without a request_id' do
        expect do
          TestJob.perform_later('some_arg')
        end.to have_enqueued_job(TestJob).with('some_arg')

        enqueued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
        expect(enqueued_job['request_id']).to be_nil
      end

      it 'does not set request_id if not provided' do
        job = TestJob.new('some_arg')
        perform_enqueued_jobs { job.perform_now }

        expect(job.arguments).to eq(['some_arg'])
        expect(job.request_id).to be_nil
      end

      it 'logs the activejob_id without a request_id' do
        job = TestJob.new('some_arg')
        allow(job.logger).to receive(:with_fields=)

        perform_enqueued_jobs { job.perform_now }

        expect(job.logger).to have_received(:with_fields=).with(hash_including(activejob_id: job.job_id, request_id: nil))
      end
    end
  end
end
