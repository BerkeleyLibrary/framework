require 'rails_helper'
require 'calnet_helper'
require 'support/async_job_context'
require 'support/holdings_contexts'

RSpec.describe HoldingsRequestsController, type: :request do
  job_classes = [Holdings::BatchJob, Holdings::WorldCatJob, Holdings::HathiTrustJob, Holdings::ResultsJob]
  job_classes.each { |job_class| include_context('async execution', job_class:) }

  describe :index do
    it 'lists requests' do
      get holdings_requests_url
      expect(response).to be_successful

      attrs = %i[email record_count completed_count error_count]
      HoldingsRequest.find_each do |req|
        attrs.each do |attr|
          expected_value = req.send(attr)
          expect(response.body).to include(expected_value.to_s)
        end
      end
    end
  end

  describe :show do
    include_context 'HoldingsRequest'

    it 'displays a request' do
      get holdings_request_url(req)
      expect(response).to be_successful
    end

    context 'complete' do
      include_context 'complete HoldingsRequest'

      it 'includes download link for results' do
        get holdings_request_url(req)
        expect(response).to be_successful
        expected_url = rails_blob_path(req.input_file, disposition: 'attachment')
        expect(response.body).to include(expected_url)
      end

      context 'with errors' do
        include_context 'complete HoldingsRequest with errors'

        it 'includes error counts' do
          get holdings_request_url(req)
          expect(response).to be_successful

          %i[record_count completed_count error_count].each do |attr|
            expected_value = req.send(attr)
            expect(response.body).to include(expected_value.to_s)
          end
        end
      end
    end
  end

  describe :new do
    it 'displays the form' do
      get new_holdings_request_url
      expect(response).to be_successful
    end
  end

  describe :create do
    include_context('HoldingsRequest')

    let(:valid_attributes) do
      {
        email: 'test@example.org',
        input_file: fixture_file_upload('spec/data/holdings/input-file.xlsx'),
        rlf: true,
        uc: true,
        hathi: true
      }
    end

    def assert_jobs_run(job_classes)
      job_classes.each { |jc| await_performed(jc) }

      expect(GoodJob::BatchRecord.exists?).to eq(true)

      aggregate_failures do
        job_classes.each do |jc|
          good_jobs = GoodJob::Job.job_class(jc.name)
          expect(good_jobs.count).to eq(1)

          good_job = good_jobs.take
          expect(good_job.error).to be_nil
          expect(good_job.finished_at).not_to be_nil
        end
      end
    end

    def assert_holdings_retrieved
      request_records = req.holdings_records
      expect(request_records.count).to eq(oclc_numbers_expected.size)

      aggregate_failures do
        request_records.find_each do |record|
          verify_ht_record_url(record)
          verify_wc_symbols(record)
        end
      end
    end

    shared_examples 'an invalid request' do
      attr_reader :user

      let(:expected_errors) do
        invalid_request = HoldingsRequest.create_from(**invalid_attributes, user:)
        invalid_request.errors
      end

      it 'does not create a request or schedule a job' do
        expect(GoodJob::Batch).not_to receive(:enqueue)

        job_classes.each do |jc|
          expect(jc).not_to receive(:perform)
        end

        expect do
          post holdings_requests_url, params: { holdings_request: invalid_attributes }
        end.not_to change(HoldingsRequest, :count)

        expect(response).not_to be_successful
        expected_errors.each do |err|
          msg_html = CGI.escapeHTML(err.message)
          expect(response.body).to include(msg_html)
        end

        expect(GoodJob::BatchRecord.exists?).to eq(false)
      end
    end

    shared_context 'stubbing API calls' do
      before do
        oclc_numbers_expected.each { |oclc_number| stub_wc_request_for(oclc_number) }
        ht_batch_uris.each { |batch_uri| stub_ht_request(batch_uri) }
      end
    end

    context 'with immediate: false' do
      context 'success' do
        include_context 'stubbing API calls'

        it 'does not start the batch job immediately' do
          travel_to(Holdings::BatchJob.start_time - 1.hours) do
            expect(GoodJob::Batch).not_to receive(:enqueue)

            job_classes.each do |jc|
              expect(jc).not_to receive(:perform)
            end

            expect do
              post holdings_requests_url, params: { holdings_request: valid_attributes }
            end.to change(HoldingsRequest, :count).by(1)

            @req = HoldingsRequest.order(created_at: :desc).take
            expect(response).to redirect_to(holdings_request_url(req))

            expect(GoodJob::BatchRecord.exists?).to eq(false)
          end
        end

        it 'schedules the batch job for 11:45 pm' do
          expect do
            post holdings_requests_url, params: { holdings_request: valid_attributes }
          end.to change(HoldingsRequest, :count).by(1)

          @req = HoldingsRequest.order(created_at: :desc).take
          expect(response).to redirect_to(holdings_request_url(req))

          travel_to(Holdings::BatchJob.start_time + 5.seconds) do
            # At this point GoodJob's already scheduled a delayed executor, so
            # we need to kill that and have it sweep again for pending jobs
            GoodJob::Scheduler.instances.each(&:restart)

            assert_jobs_run(job_classes)
            assert_holdings_retrieved
          end
        end
      end
    end

    context 'with immediate: true' do
      before do
        valid_attributes[:immediate] = true
      end

      context 'as admin' do
        before { @user = login_as_patron(Alma::FRAMEWORK_ADMIN_ID) }

        after { logout! }

        context 'success' do
          include_context 'stubbing API calls'

          before do
            HoldingsRequest.destroy_all # just to be sure
            expect(HoldingsRequest.exists?).to eq(false) # just to be sure

            expect do
              post holdings_requests_url, params: { holdings_request: valid_attributes }
            end.to change(HoldingsRequest, :count).by(1)

            @req = HoldingsRequest.order(created_at: :desc).take
            expect(response).to redirect_to(holdings_request_url(req))
          end

          it 'executes background jobs' do
            assert_jobs_run(job_classes)
            assert_holdings_retrieved
          end

          # TODO: test UI
        end

        context 'failure' do
          context 'email not present' do
            it_behaves_like 'an invalid request' do
              let(:invalid_attributes) { valid_attributes.except(:email) }
            end
          end

          context 'input file not present' do
            it_behaves_like 'an invalid request' do
              let(:invalid_attributes) { valid_attributes.except(:input_file) }
            end
          end

          context 'no include flags present' do
            it_behaves_like 'an invalid request' do
              let(:invalid_attributes) { valid_attributes.except(:rlf, :uc, :hathi) }
            end
          end

          context 'wrong spreadsheet format' do
            it_behaves_like 'an invalid request' do
              let(:invalid_attributes) { valid_attributes.merge(input_file: fixture_file_upload('spec/data/holdings/input-file-excel95.xls')) }
            end
          end

          context 'empty spreadsheet' do
            it_behaves_like 'an invalid request' do
              let(:invalid_attributes) { valid_attributes.merge(input_file: fixture_file_upload('spec/data/holdings/input-file-empty.xlsx')) }
            end
          end
        end
      end

      context 'without login' do
        it_behaves_like 'an invalid request' do
          let(:invalid_attributes) { valid_attributes }
        end
      end

      context 'with non-admin login' do
        before { @user = login_as_patron(Alma::NON_FRAMEWORK_ADMIN_ID) }

        after { logout! }

        it_behaves_like 'an invalid request' do
          let(:invalid_attributes) { valid_attributes }
        end
      end
    end
  end

  describe :result do
    context 'success' do
      include_context 'complete HoldingsRequest'

      it 'redirects to the blob download path' do
        req.ensure_output_file!

        expected_path = rails_blob_path(req.output_file, disposition: 'attachment')
        get(holdings_requests_result_url(req))

        expect(response).to redirect_to(expected_path)
      end
    end

    context 'failure' do
      include_context('HoldingsRequest')

      it 'returns 404 not found' do
        expect(req).to be_incomplete # just to be sure

        get(holdings_requests_result_url(req))

        expect(response).not_to be_successful
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
