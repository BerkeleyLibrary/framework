require 'rails_helper'
require 'calnet_helper'
require 'support/async_job_context'
require 'support/location_contexts'

RSpec.describe LocationRequestsController, type: :request do
  job_classes = [Location::BatchJob, Location::WorldCatJob, Location::HathiTrustJob, Location::ResultsJob]
  job_classes.each { |job_class| include_context('async execution', job_class:) }

  describe :index do
    context 'without login' do
      it 'redirects to login' do
        get location_requests_url
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: location_requests_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end

    context 'as admin' do

      shared_examples 'a list of requests' do
        it 'lists requests' do
          get location_requests_url
          expect(response).to be_successful

          attrs = %i[email filename record_count completed_count error_count]
          LocationRequest.find_each do |req|
            attrs.each do |attr|
              expected_value = req.send(attr)
              expect(response.body).to include(expected_value.to_s)
            end
          end
        end
      end

      before { @user = login_as_patron(Alma::FRAMEWORK_ADMIN_ID) }

      after { logout! }

      context('with no requests') do
        # just to be sure
        before { expect(LocationRequest).not_to exist }

        it_behaves_like('a list of requests')
      end

      context('with incomplete request') do
        include_context('incomplete LocationRequest')
        it_behaves_like('a list of requests')
      end

      context('with incomplete request with errors') do
        include_context('incomplete LocationRequest with errors')
        it_behaves_like('a list of requests')
      end

      context('with complete request with errors') do
        include_context('complete LocationRequest with errors')
        it_behaves_like('a list of requests')
      end

      context('with location records') do
        include_context('complete LocationRequest')
        it_behaves_like('a list of requests')
      end

      context 'with broken input file' do
        include_context('LocationRequest with broken input file attachment')
        it_behaves_like('a list of requests')
      end

      context 'with broken output file' do
        include_context('LocationRequest with broken output file attachment')
        it_behaves_like('a list of requests')
      end
    end

    context 'with non-admin login' do
      before { @user = login_as_patron(Alma::NON_FRAMEWORK_ADMIN_ID) }

      after { logout! }

      it 'is forbidden' do
        get location_requests_url
        expect(response.status).to eq(403)
      end
    end
  end

  describe :show do
    include_context 'LocationRequest'

    shared_examples 'a list of errors' do
      it 'lists the errors' do
        get location_request_url(req)
        expect(response).to be_successful

        body_html = Nokogiri::HTML(response.body)

        expected_records = req.records_with_errors.limit(LocationRequest::MAX_ERRORS_TO_DISPLAY)
        expected_records.find_each do |rec|
          rec_html = body_html.search("//*[@id='location_record_#{rec.id}.errors']").first
          expect(rec_html).not_to be_nil

          rec_html_str = rec_html.to_s

          expected_values = [rec.oclc_number, rec.wc_error, rec.ht_error].compact
          expected_values.each { |v| expect(rec_html_str).to include(v) }
        end
      end
    end

    it 'displays a request' do
      get location_request_url(req)
      expect(response).to be_successful
    end

    context 'complete' do
      include_context 'complete LocationRequest'

      it 'includes download link for results' do
        get location_request_url(req)
        expect(response).to be_successful
        expected_url = rails_blob_path(req.input_file, disposition: 'attachment')
        expect(response.body).to include(expected_url)
      end

      context 'with errors' do
        include_context 'complete LocationRequest with errors'
        it_behaves_like 'a list of errors'
      end
    end

    context 'incomplete' do
      context 'with errors' do
        include_context 'incomplete LocationRequest with errors'
        it_behaves_like 'a list of errors'
      end
    end
  end

  describe :new do
    it 'displays the form' do
      get new_location_request_url
      expect(response).to be_successful
    end
  end

  describe :create do
    include_context('LocationRequest')

    let(:valid_attributes) do
      {
        email: 'test@example.org',
        input_file: fixture_file_upload('spec/data/location/input-file.xlsx'),
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

    def assert_location_retrieved
      request_records = req.location_records
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
        invalid_request = LocationRequest.create_from(**invalid_attributes, user:)
        invalid_request.errors
      end

      it 'does not create a request or schedule a job' do
        expect(GoodJob::Batch).not_to receive(:enqueue)

        job_classes.each { |jc| expect(jc).not_to receive(:perform) }

        expect do
          post location_requests_url, params: { location_request: invalid_attributes }
        end.not_to change(LocationRequest, :count)

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
        before { stub_token_request }

        include_context 'stubbing API calls'

        it 'does not start the batch job immediately' do
          LocationRequest.destroy_all
          start_time = Location::BatchJob.start_time
          travel_to(start_time - 1.hours) do
            expect(GoodJob::Batch).not_to receive(:enqueue)

            job_classes.each do |jc|
              expect(jc).not_to receive(:perform)
            end

            expect do
              post location_requests_url, params: { location_request: valid_attributes }
            end.to change(LocationRequest, :count).by(1)

            @req = LocationRequest.order(created_at: :desc).take
            expect(response).to redirect_to(location_request_url(req))

            expect(GoodJob::BatchRecord.exists?).to eq(false)
          end
        end

        it 'schedules the batch job for 11:45 pm' do
          start_time = Location::BatchJob.start_time

          expect do
            post location_requests_url, params: { location_request: valid_attributes }
          end.to change(LocationRequest, :count).by(1)

          @req = LocationRequest.order(created_at: :desc).take
          expect(response).to redirect_to(location_request_url(req))
          expect(req.scheduled_at).to eq(start_time)

          travel_to(start_time + 5.seconds) do
            # At this point GoodJob's already scheduled a delayed executor, so
            # we need to kill that and have it sweep again for pending jobs
            GoodJob::Scheduler.instances.each(&:restart)

            assert_jobs_run(job_classes)
            assert_location_retrieved
          end
        end
      end

      context 'failure' do
        describe 'when unable to upload input file' do
          it 'does not create a request' do
            expect(ActiveStorage::Blob.service).to receive(:make_path_for).and_raise(Errno::EACCES)

            expect(GoodJob::Batch).not_to receive(:enqueue)

            job_classes.each { |jc| expect(jc).not_to receive(:perform) }

            blob_count_before = ActiveStorage::Blob.count
            attachment_count_before = ActiveStorage::Attachment.count
            request_count_before = LocationRequest.count

            expect do
              post location_requests_url, params: { location_request: valid_attributes }
            end.to raise_error(Errno::EACCES)

            expect(LocationRequest.count).to eq(request_count_before)
            expect(ActiveStorage::Attachment.count).to eq(attachment_count_before)
            expect(ActiveStorage::Blob.count).to eq(blob_count_before)

            expect(GoodJob::BatchRecord.exists?).to eq(false)
          end
        end
      end
    end

    context 'with immediate: true' do
      before do
        stub_token_request
        valid_attributes[:immediate] = true
      end

      context 'as admin' do
        before do
          stub_token_request
          @user = login_as_patron(Alma::FRAMEWORK_ADMIN_ID)
        end

        after { logout! }

        context 'success' do
          include_context 'stubbing API calls'

          before do
            LocationRequest.destroy_all # just to be sure
            expect(LocationRequest.exists?).to eq(false) # just to be sure

            expect do
              post location_requests_url, params: { location_request: valid_attributes }
            end.to change(LocationRequest, :count).by(1)

            @req = LocationRequest.order(created_at: :desc).take
            expect(response).to redirect_to(location_request_url(req))
            expect(req.scheduled_at).to be_within(1.minutes).of(Time.current)
          end

          it 'executes background jobs' do
            expect do
              assert_jobs_run(job_classes)
              assert_location_retrieved
            end.to(change { ActionMailer::Base.deliveries.count })

            message = ActionMailer::Base.deliveries.find { |m| m.to && m.to.include?(req.email) }
            expect(message).not_to be_nil

            attachments = message.attachments
            expect(attachments.size).to eq(1)

            attachment = attachments[0]
            expect(attachment.content_type).to eq(mime_type_xlsx)
            expect(attachment.filename).to eq(req.output_filename)
          end
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
              let(:invalid_attributes) { valid_attributes.merge(input_file: fixture_file_upload('spec/data/location/input-file-excel95.xls')) }
            end
          end

          context 'empty spreadsheet' do
            it_behaves_like 'an invalid request' do
              let(:invalid_attributes) { valid_attributes.merge(input_file: fixture_file_upload('spec/data/location/input-file-empty.xlsx')) }
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
      include_context 'complete LocationRequest'

      it 'redirects to the blob download path' do
        req.ensure_output_file!

        expected_path = rails_blob_path(req.output_file, disposition: 'attachment')
        get(location_requests_result_url(req))

        expect(response).to redirect_to(expected_path)
      end
    end

    context 'failure' do
      include_context('LocationRequest')

      it 'returns 404 not found' do
        expect(req).to be_incomplete # just to be sure

        get(location_requests_result_url(req))

        expect(response).not_to be_successful
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
