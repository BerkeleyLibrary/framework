require 'rails_helper'
require 'support/async_job_context'
require 'support/holdings_contexts'

RSpec.describe HoldingsTasksController, type: :request do
  let(:valid_attributes) do
    {
      email: 'test@example.org',
      input_file: fixture_file_upload('spec/data/holdings/input-file.xlsx'),
      rlf: true,
      uc: true,
      hathi: true
    }
  end

  # let(:invalid_attributes) do
  #   skip('Add a hash of attributes invalid for your model')
  # end
  #
  # describe 'GET /index' do
  #   it 'renders a successful response' do
  #     HoldingsTask.create! valid_attributes
  #     get holdings_tasks_url
  #     expect(response).to be_successful
  #   end
  # end
  #
  # describe 'GET /show' do
  #   it 'renders a successful response' do
  #     holdings_task = HoldingsTask.create! valid_attributes
  #     get holdings_task_url(holdings_task)
  #     expect(response).to be_successful
  #   end
  # end
  #
  # describe 'GET /new' do
  #   it 'renders a successful response' do
  #     get new_holdings_task_url
  #     expect(response).to be_successful
  #   end
  # end
  #
  # describe 'GET /edit' do
  #   it 'renders a successful response' do
  #     holdings_task = HoldingsTask.create! valid_attributes
  #     get edit_holdings_task_url(holdings_task)
  #     expect(response).to be_successful
  #   end
  # end

  describe :create do
    include_context('HoldingsTask')

    job_classes = [Holdings::WorldCatJob, Holdings::HathiTrustJob, Holdings::ResultsJob]
    job_classes.each { |job_class| include_context('async execution', job_class:) }

    context 'success' do
      before do
        oclc_numbers_expected.each { |oclc_number| stub_wc_request_for(oclc_number) }
        ht_batch_uris.each { |batch_uri| stub_ht_request(batch_uri) }

        HoldingsTask.destroy_all # just to be sure
        expect(HoldingsTask.exists?).to eq(false) # just to be sure

        expect do
          post holdings_tasks_url, params: { holdings_task: valid_attributes }
        end.to change(HoldingsTask, :count).by(1)

        @task = HoldingsTask.take
      end

      it 'executes background jobs' do
        expect(GoodJob::BatchRecord.exists?).to eq(true)

        job_classes.each { |jc| await_performed(jc) }

        aggregate_failures do
          job_classes.each do |jc|
            good_jobs = GoodJob::Job.job_class(jc.name)
            expect(good_jobs.count).to eq(1)

            good_job = good_jobs.take
            expect(good_job.error).to be_nil
            expect(good_job.finished_at).not_to be_nil
          end
        end

        task_records = task.holdings_records
        expect(task_records.count).to eq(oclc_numbers_expected.size)

        aggregate_failures do
          task_records.find_each do |record|
            verify_ht_record_url(record)
            verify_wc_symbols(record)
          end
        end
      end

      # TODO: test UI
    end

    context 'failure' do
      shared_examples 'an invalid request' do
        it 'does not create a task or schedule a job' do
          expect(GoodJob::Batch).not_to receive(:enqueue)

          job_classes.each do |jc|
            expect(jc).not_to receive(:perform)
          end

          expect do
            post holdings_tasks_url, params: { holdings_task: invalid_attributes }
          end.not_to change(HoldingsTask, :count)

          expect(GoodJob::BatchRecord.exists?).to eq(false)
        end

        # TODO: test UI
      end

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

  # describe 'POST /create' do
  #   context 'with valid parameters' do
  #     it 'creates a new HoldingsTask' do
  #       expect do
  #         post holdings_tasks_url, params: { holdings_task: valid_attributes }
  #       end.to change(HoldingsTask, :count).by(1)
  #     end
  #
  #     it 'redirects to the created holdings_task' do
  #       post holdings_tasks_url, params: { holdings_task: valid_attributes }
  #       expect(response).to redirect_to(holdings_task_url(HoldingsTask.last))
  #     end
  #   end
  #
  #   context 'with invalid parameters' do
  #     it 'does not create a new HoldingsTask' do
  #       expect do
  #         post holdings_tasks_url, params: { holdings_task: invalid_attributes }
  #       end.to change(HoldingsTask, :count).by(0)
  #     end
  #
  #     it "renders a successful response (i.e. to display the 'new' template)" do
  #       post holdings_tasks_url, params: { holdings_task: invalid_attributes }
  #       expect(response).to be_successful
  #     end
  #   end
  # end
  #
  # describe 'PATCH /update' do
  #   context 'with valid parameters' do
  #     let(:new_attributes) do
  #       skip('Add a hash of attributes valid for your model')
  #     end
  #
  #     it 'updates the requested holdings_task' do
  #       holdings_task = HoldingsTask.create! valid_attributes
  #       patch holdings_task_url(holdings_task), params: { holdings_task: new_attributes }
  #       holdings_task.reload
  #       skip('Add assertions for updated state')
  #     end
  #
  #     it 'redirects to the holdings_task' do
  #       holdings_task = HoldingsTask.create! valid_attributes
  #       patch holdings_task_url(holdings_task), params: { holdings_task: new_attributes }
  #       holdings_task.reload
  #       expect(response).to redirect_to(holdings_task_url(holdings_task))
  #     end
  #   end
  #
  #   context 'with invalid parameters' do
  #     it "renders a successful response (i.e. to display the 'edit' template)" do
  #       holdings_task = HoldingsTask.create! valid_attributes
  #       patch holdings_task_url(holdings_task), params: { holdings_task: invalid_attributes }
  #       expect(response).to be_successful
  #     end
  #   end
  # end
  #
  # describe 'DELETE /destroy' do
  #   it 'destroys the requested holdings_task' do
  #     holdings_task = HoldingsTask.create! valid_attributes
  #     expect do
  #       delete holdings_task_url(holdings_task)
  #     end.to change(HoldingsTask, :count).by(-1)
  #   end
  #
  #   it 'redirects to the holdings_tasks list' do
  #     holdings_task = HoldingsTask.create! valid_attributes
  #     delete holdings_task_url(holdings_task)
  #     expect(response).to redirect_to(holdings_tasks_url)
  #   end
  # end
end
