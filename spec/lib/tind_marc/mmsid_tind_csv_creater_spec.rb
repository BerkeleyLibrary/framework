require 'support/tind_marc_contexts'
module TindMarc
  RSpec.describe MmsidTindCsvCreater do
    let(:mmsid_tind_csv_creater) { described_class.new(batch_info) }
    let(:res_204) { instance_double(Net::HTTPSuccess, code: '204', message: 'no_content', body: '') }

    describe '#MmsidTindCsvCreater: get 204 response' do
      include_context 'setup_with_args_and_tind_request', :directory_batch_path
      it 'add an error to attribute errors' do
        allow_any_instance_of(Net::HTTP)
          .to receive(:request).and_return(res_204)
        expect { mmsid_tind_csv_creater.rows }.to change { mmsid_tind_csv_creater.errors.count }.by(1)
      end

    end
  end
end
