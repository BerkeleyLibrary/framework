require 'support/tind_marc_contexts'
require 'webmock/rspec'

module TindMarc
  RSpec.describe TindBatchCreator do
    let(:tind_batch_creator) { described_class.new(args) }

    describe '#TindBatchCreator: directory batch, normal labels.csv file, with append tind_mmsid info' do
      include_context 'setup_with_args', :directory_batch_path, 'normal', 'with_append'

      it 'generate only one append record' do
        hash = tind_batch_creator.records_hash
        expect(hash[:inserts].length).to eq(0)
        expect(hash[:appends].length).to eq(1)
      end
    end

    describe '#TindBatchCreator: directory batch, no append tind_mmsid info  ' do
      include_context 'setup_with_args_and_alma_request', :directory_batch_path, nil, 'no_append'
      it 'generate one insert record - need to get matadata from Alma' do
        hash = tind_batch_creator.records_hash
        expect(hash[:inserts].length).to eq(1)
        expect(hash[:appends].length).to eq(0)
      end
    end

    describe '#TindBatchCreator: directory batch, less labels.csv file, no append tind_mmsid info' do
      include_context 'setup_with_args_and_alma_request', :directory_batch_path, 'less', 'no_append'
      it 'create an insert record even without label from csv file for a digital file' do
        expect { tind_batch_creator.records_hash }.to change { tind_batch_creator.warnings.length }.by(3)
      end
    end

    describe '#TindBatchCreator: directory batch, no labels.csv file, with both_columns_empty tind_mmsid info' do
      include_context 'setup_with_args', :directory_batch_path, 'more', 'both_columns_empty'
      it 'create an error message' do
        expect(tind_batch_creator.critical_errors.length).to eq(1)
        expect(tind_batch_creator.warnings.length).to eq(1)
      end
    end

    describe '#TindBatchCreator: directory batch, no labels.csv file, with both_columns_not_empty tind_mmsid info' do
      include_context 'setup_with_args', :directory_batch_path, nil, 'both_columns_not_empty'
      it 'create an error message' do
        expect(tind_batch_creator.critical_errors.length).to eq(1)
      end
    end

    describe '#TindBatchCreator: directory batch, no lable.csv file, no tind_mmsid info, failed to create an insert record' do
      include_context 'setup_with_args', :directory_batch_path, nil, nil
      it 'failed to create an insert record' do
        allow(BerkeleyLibrary::TIND::Mapping::AlmaSingleTIND).to receive(:new).and_raise(StandardError)
        expect { tind_batch_creator.records_hash }.to change(tind_batch_creator.errors, :length).by(1)
      end
    end

    describe '#TindBatchCreator: directory batch, no lable.csv file, append tind_mmsid info, failed to create an append record' do
      include_context 'setup_with_args_and_tind_request', :directory_batch_path, nil, 'with_append'
      it 'failed to create append record' do
        allow(::MARC::Record).to receive(:new).and_raise(StandardError)
        expect { tind_batch_creator.records_hash }.to change(tind_batch_creator.errors, :length).by(1)
      end
    end

    describe '#TindBatchCreator: directory batch, lable.csv file, no tind_mmsid info, mock to one critical error' do
      include_context 'setup_with_args', :directory_batch_path, 'normal'
      it 'create one critical error during validation' do
        allow(CSV).to receive(:read).and_raise(StandardError)
        tind_batch_creator = described_class.new(args)
        expect(tind_batch_creator.critical_errors.length).to eq(1)
      end
    end

    describe '#TindBatchCreator: directory batch, lable.csv file, no_append tind_mmsid info, mock two critical error' do
      include_context 'setup_with_args', :directory_batch_path, 'normal', 'no_append'
      it 'create two critical errors during validation' do
        allow(CSV).to receive(:read).and_raise(StandardError)
        tind_batch_creator = described_class.new(args)
        expect(tind_batch_creator.critical_errors.length).to eq(2)
      end
    end

  end
end
