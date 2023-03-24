require 'rails_helper'
require 'support/holdings_contexts'

module Holdings
  describe ResultsJob, type: :job do
    include_context('complete HoldingsTask')

    context 'success' do
      it 'attaches the output file' do
        expect(task.output_file).not_to be_attached

        ResultsJob.perform_now(task)
        assert_output_complete!(task)
      end

      context 'with existing output' do
        before do
          task.ensure_output_file!
        end

        it 'does not re-create an existing output file' do
          expect(BerkeleyLibrary::Holdings::XLSXWriter).not_to receive(:new)

          ResultsJob.perform_now(task)
          assert_output_complete!(task)
        end
      end
    end
  end
end
