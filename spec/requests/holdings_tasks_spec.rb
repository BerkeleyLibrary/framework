require 'rails_helper'
require 'support/async_job_context'

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
    context 'success' do
      include_context('async execution', job_class: Holdings::WorldCatJob)
      include_context('async execution', job_class: Holdings::HathiTrustJob)
      include_context('async execution', job_class: Holdings::ResultsJob)

      it 'creates a new HoldingsTask and schedules a job' do
        expect do
          post holdings_tasks_url, params: { holdings_task: valid_attributes }
        end.to change(HoldingsTask, :count).by(1)

        expect(GoodJob::BatchRecord.exists?).to eq(true)

        # TODO: figure out why errors other than StandardError (e.g. WebMock) don't stop execution
        [Holdings::WorldCatJob, Holdings::HathiTrustJob, Holdings::ResultsJob].each do |jc|
          await_performed(jc, timeout: 1000)
        end
      end
    end

    context 'failure' do
      shared_examples 'an invalid request' do
        it 'does not create a task or schedule a job' do
          expect(GoodJob::Batch).not_to receive(:enqueue)

          [Holdings::WorldCatJob, Holdings::HathiTrustJob, Holdings::ResultsJob].each do |jc|
            expect(jc).not_to receive(:perform)
          end

          expect do
            post holdings_tasks_url, params: { holdings_task: invalid_attributes }
          end.not_to change(HoldingsTask, :count)
        end
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
