require 'rails_helper'
require 'support/holdings_contexts'

module Holdings
  describe ResultsJob, type: :job do
    include_context('complete HoldingsTask')

    attr_reader :batch, :params

    before do
      @batch = instance_double(GoodJob::Batch).tap do |batch|
        allow(batch).to receive(:id).and_return('test-batch-id')
        allow(batch).to receive(:properties).and_return({ task: @task })
      end

      @params = { event: :finish }
    end

    context 'success' do
      it 'attaches the output file' do
        expect(task.output_file).not_to be_attached # just to be sure

        ResultsJob.perform_now(batch, params)
        assert_output_complete!(task)
      end

      context 'with existing output' do
        before do
          task.ensure_output_file!
        end

        it 'does not re-create an existing output file' do
          expect(BerkeleyLibrary::Holdings::XLSXWriter).not_to receive(:new)

          ResultsJob.perform_now(batch, params)
          assert_output_complete!(task)
        end
      end

      # TODO: test email
    end
  end
end
