require 'support/tind_marc_contexts'
module TindMarc
  RSpec.describe MmsidTindTask do
    let(:mmsid_tind_task) { described_class.new(args, email) }

    shared_examples 'run_and_send_email' do |type_sym|
      let(:directory) { Rails.root.join('spec/data/tind_marc/data/da/directory_collection/ucb/incoming') }
      let(:subject) do # rubocop:disable RSpec/SubjectDeclaration
        { completed: "Completed to obtain TIND and MMSID information for the batch at: #{directory}",
          failed: "Critical error, cann not obtain TIND and MMSID CSV file Directory: #{directory}" }
      end

      it "run and send #{type_sym} email" do
        mmsid_tind_task.run
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq(subject[type_sym])
      end
    end

    describe '#MmsidTindTask: succeed run' do
      include_context 'setup_with_args_and_tind_request', :directory_batch_path

      context 'send completed email' do
        it_behaves_like 'run_and_send_email', :completed
      end

      context 'save file to local in develpment env' do
        let(:mmsid_tind_csv_file_path) { Rails.root.join('tmp', 'mmsid_tind', 'mmsid_tind_directory_collection_ucb_incoming.csv') }

        before do
          rm_file
        end

        after do
          rm_file
        end

        def rm_file
          FileUtils.rm_f(mmsid_tind_csv_file_path)
        end

        it 'save tind-mmsid csv file' do
          allow(Rails.env).to receive(:development?).and_return(true)
          mmsid_tind_task.run
          expect(File.exist?(mmsid_tind_csv_file_path)).to be true
        end
      end

      context 'send completed email with normal errors' do
        before do
          allow_any_instance_of(MmsidTindCsvCreater)
            .to receive(:errors).and_return(%w[error1 error2 error3])
        end

        it_behaves_like 'run_and_send_email', :completed
      end

      context 'failed run with critical error' do
        before do
          allow(Net::HTTP).to receive(:new).and_raise(StandardError.new('Network failure'))
        end

        it_behaves_like 'run_and_send_email', :failed
      end

    end

  end
end
