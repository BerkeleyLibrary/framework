require 'rails_helper'
require 'support/async_job_context'
require 'support/holdings_contexts'

module Holdings
  describe BatchJob, type: :job do
    job_classes = [Holdings::BatchJob, Holdings::WorldCatJob, Holdings::HathiTrustJob, Holdings::ResultsJob, Holdings::RequestFailedJob]
    job_classes.each { |job_class| include_context('async execution', job_class:) }

    include_context('HoldingsRequest')

    attr_reader :result_url

    before do
      ht_batch_uris.each { |batch_uri| stub_ht_request(batch_uri) }
      oclc_numbers_expected.each { |oclc_number| stub_wc_request_for(oclc_number) }

      url_helpers = Rails.application.routes.url_helpers
      @result_url = url_helpers.holdings_requests_result_url(@req, host: 'framework.example.edu')
    end

    context 'success' do
      it 'processes the request' do
        expect(req.output_file).not_to be_attached # just to be sure

        expect do
          BatchJob.perform_later(req, result_url)
          await_performed(BatchJob)
          await_performed(ResultsJob)
        end.to(change { ActionMailer::Base.deliveries.count })

        message = ActionMailer::Base.deliveries.find { |m| m.to && m.to.include?(req.email) }
        expect(message).not_to be_nil

        attachments = message.attachments
        expect(attachments.size).to eq(1)

        attachment = attachments[0]
        expect(attachment.content_type).to eq(mime_type_xlsx)
        expect(attachment.filename).to eq(req.output_filename)

        # TODO: better testing of body
        expect(message.to_s).to include(result_url)
      end
    end

    context 'failure' do
      let(:error) { 'Help I am trapped in a unit test' }

      context 'failure in WorldCat holdings retrieval' do
        before do
          allow_any_instance_of(WorldCatJob).to receive(:perform).and_raise(error)
        end

        it 'sends a failure email' do
          expect(req.output_file).not_to be_attached # just to be sure

          expect do
            BatchJob.perform_later(req, result_url)
            await_performed(BatchJob)
            await_performed(RequestFailedJob)
          end.to(change { ActionMailer::Base.deliveries.count })

          expect(req.output_file).not_to be_attached # just to be sure

          message = ActionMailer::Base.deliveries.find { |m| m.to && m.to.include?(req.email) }
          expect(message).not_to be_nil

          attachments = message.attachments
          expect(attachments).to be_empty

          # TODO: better testing of body
          expect(message.to_s).to include(error.to_s)
        end
      end

      context 'failure in HathiTrust record retrieval' do
        before do
          allow_any_instance_of(HathiTrustJob).to receive(:perform).and_raise(error)
        end

        it 'sends a failure email' do
          expect(req.output_file).not_to be_attached # just to be sure

          expect do
            BatchJob.perform_later(req, result_url)
            await_performed(BatchJob)
            await_performed(RequestFailedJob)
          end.to(change { ActionMailer::Base.deliveries.count })

          expect(req.output_file).not_to be_attached # just to be sure

          message = ActionMailer::Base.deliveries.find { |m| m.to && m.to.include?(req.email) }
          expect(message).not_to be_nil

          attachments = message.attachments
          expect(attachments).to be_empty

          # TODO: better testing of body
          expect(message.to_s).to include(error.to_s)
        end
      end

      context 'failure in results generation' do
        before do
          allow_any_instance_of(HoldingsRequest).to receive(:ensure_output_file!).and_raise(error)
        end

        it 'sends a failure email' do
          expect(req.output_file).not_to be_attached # just to be sure

          expect do
            BatchJob.perform_later(req, result_url)
            await_performed(BatchJob)
            await_performed(ResultsJob)
          end.to(change { ActionMailer::Base.deliveries.count })

          expect(req.output_file).not_to be_attached # just to be sure

          message = ActionMailer::Base.deliveries.find { |m| m.to && m.to.include?(req.email) }
          expect(message).not_to be_nil

          attachments = message.attachments
          expect(attachments).to be_empty

          # TODO: better testing of body
          expect(message.to_s).to include(error.to_s)
        end
      end
    end
  end
end
