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

      it 'sends email' do
        expect { ResultsJob.perform_now(batch, params) }.to(change { ActionMailer::Base.deliveries.count })
        message = ActionMailer::Base.deliveries.select { |m| m.to && m.to.include?(task.email) }
        expect(message).not_to be_nil

        expected_subject = I18n.t('holdings_mailer.holdings_results.subject')
        expect(message.subject).to eq(expected_subject)

        # TODO: attachment
        expect(message.body).to eq('elvis')
      end

    end
  end
end
