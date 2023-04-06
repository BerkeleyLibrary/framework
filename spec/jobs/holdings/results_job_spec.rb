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

      it 'sends email' do
        expect { ResultsJob.perform_now(batch, params) }.to(change { ActionMailer::Base.deliveries.count })
        message = ActionMailer::Base.deliveries.find { |m| m.to && m.to.include?(task.email) }
        expect(message).not_to be_nil

        expected_subject = I18n.t('holdings_mailer.holdings_results.subject')
        expect(message.subject).to eq(expected_subject)
        expect(message.recipients).to include(task.email)

        attachments = message.attachments
        expect(attachments.size).to eq(1)

        attachment = attachments[0]
        expect(attachment.content_type).to eq(mime_type_xlsx)
        expect(attachment.filename).to eq(task.output_filename)

        expected_data = task.output_file.download
        attachment_data = attachment.body.decoded
        expect(attachment_data).to eq(expected_data)

        # TODO: better testing of body
        expected_url = Rails.application.routes.url_helpers.holdings_tasks_result_path(task)
        expect(message.to_s).to include(expected_url)
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

      context 'with errors' do
        before do
          task.holdings_records.find_each.with_index do |r, i|
            if i.even?
              r.update(wc_symbols: nil, wc_error: '403 Forbidden')
            elsif i % 3 == 0
              r.update(ht_record_url: nil, ht_error: '500 Internal Server Error')
            end
          end
        end

        it 'sends email' do
          expect { ResultsJob.perform_now(batch, params) }.to(change { ActionMailer::Base.deliveries.count })
          message = ActionMailer::Base.deliveries.find { |m| m.to && m.to.include?(task.email) }
          expect(message).not_to be_nil

          expect(task.error_count).to be > 0 # just to be sure
          expected_report = HoldingsMailer.error_report_for(task)
          message_text = message.to_s.gsub("\r\n", "\n")
          expect(message_text).to include(expected_report)
        end
      end
    end
  end
end
