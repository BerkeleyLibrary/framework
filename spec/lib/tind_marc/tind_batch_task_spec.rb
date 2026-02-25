require 'support/tind_marc_contexts'

module TindMarc
  RSpec.describe TindBatchTask do
    let(:tind_batch_task) { described_class.new(args, email) }

    shared_examples 'run_and_send_email' do |type_sym|
      let(:subject) do # rubocop:disable RSpec/SubjectDeclaration
        { completed: 'Completed: Tind batch file(s) created for Air Photos - directory_collection/ucb/incoming',
          failed: 'Cannot create Tind batch, please check with support team. Directory: directory_collection/ucb/incoming' }
      end
      it "run and send #{type_sym} email" do
        tind_batch_task.run
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq(subject[type_sym])
      end
    end

    describe '#TindBatchTask: directory batch, normal labels.csv file, with append tind_mmsid info' do
      include_context 'setup_with_args', :directory_batch_path, 'normal', 'with_append'
      context 'run successfully, send a completed emmail' do
        it_behaves_like 'run_and_send_email', :completed
      end

      context 'run successfully, and save file to local in develpment env' do
        let(:tind_marc_append_batch_file_path) { Rails.root.join('tmp', 'tind_marc_batch', 'append_result.xml') }

        before do
          rm_file
        end

        after do
          rm_file
        end

        def rm_file
          FileUtils.rm_f(tind_marc_append_batch_file_path)
        end

        it 'save an append batch file' do
          allow(Rails.env).to receive(:development?).and_return(true)
          tind_batch_task.run
          expect(File.exist?(tind_marc_append_batch_file_path)).to be true
        end
      end

    end

    describe '#TindBatchTask: directory batch, less labels.csv file, no append tind_mmsid info' do
      include_context 'setup_with_args_and_alma_request', :directory_batch_path, 'less', 'no_append'
      it_behaves_like 'run_and_send_email', :completed
    end

    describe '#TindBatchTask: directory batch, incorrect_header, labels.csv file, no append tind_mmsid info' do
      include_context 'setup_with_args', :directory_batch_path, 'incorrect_header', 'no_append'
      it_behaves_like 'run_and_send_email', :failed
    end

  end

end
