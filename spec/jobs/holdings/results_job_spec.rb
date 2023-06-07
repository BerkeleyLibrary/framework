require 'rails_helper'
require 'support/holdings_contexts'

module Holdings
  describe ResultsJob, type: :job do
    include_context('complete HoldingsRequest')

    attr_reader :batch, :params

    before do
      url_helpers = Rails.application.routes.url_helpers

      @batch = instance_double(GoodJob::Batch).tap do |batch|
        allow(batch).to receive(:id).and_return('test-batch-id')
        allow(batch).to receive(:properties) do
          {
            request: @req,
            result_url: url_helpers.holdings_requests_result_url(@req, host: 'framework.example.edu')
          }
        end
      end

      @params = { event: :finish }
    end

    context 'success' do
      it 'attaches the output file' do
        expect(req.output_file).not_to be_attached # just to be sure

        ResultsJob.perform_now(batch, params)
        assert_output_complete!(req)
      end

      it 'sends email' do
        expect { ResultsJob.perform_now(batch, params) }.to(change { ActionMailer::Base.deliveries.count })
        message = ActionMailer::Base.deliveries.find { |m| m.to && m.to.include?(req.email) }
        expect(message).not_to be_nil

        expected_subject = I18n.t('holdings_mailer.holdings_results.subject')
        expect(message.subject).to eq(expected_subject)
        expect(message.recipients).to include(req.email)

        attachments = message.attachments
        expect(attachments.size).to eq(1)

        attachment = attachments[0]
        expect(attachment.content_type).to eq(mime_type_xlsx)
        expect(attachment.filename).to eq(req.output_filename)

        expected_data = req.output_file.download
        attachment_data = attachment.body.decoded
        expect(attachment_data).to eq(expected_data)

        # TODO: better testing of body
        expected_url = Rails.application.routes.url_helpers.holdings_requests_result_path(req)
        expect(message.to_s).to include(expected_url)
      end

      context 'with existing output' do
        before do
          req.ensure_output_file!
        end

        it 'does not re-create an existing output file' do
          expect(BerkeleyLibrary::Location::XLSXWriter).not_to receive(:new)

          ResultsJob.perform_now(batch, params)
          assert_output_complete!(req)
        end
      end

      context 'with errors' do
        include_context('complete HoldingsRequest with errors')

        it 'sends email' do
          expect { ResultsJob.perform_now(batch, params) }.to(change { ActionMailer::Base.deliveries.count })
          message = ActionMailer::Base.deliveries.find { |m| m.to && m.to.include?(req.email) }
          expect(message).not_to be_nil

          expect(req.error_count).to be > 0 # just to be sure
          expected_report = HoldingsMailer.record_errors_for(req)
          message_text = message.to_s.gsub("\r\n", "\n")
          expect(message_text).to include(expected_report)
        end
      end
    end
  end
end
