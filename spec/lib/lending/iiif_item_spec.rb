require 'rails_helper'
require 'lending'

module Lending

  describe IIIFItem do
    describe :create_from do
      let(:source_dir) { 'spec/data/lending/incoming/b11996535_B 3 106 704' }
      let(:directory) { File.basename(source_dir) }

      attr_reader :iiif_final_dir

      describe 'with valid directories' do
        before(:each) do
          @iiif_final_dir = Dir.mktmpdir
          allow(Rails.application.config).to receive(:iiif_source_dir).and_return('spec/data/lending/incoming')
          allow(Rails.application.config).to receive(:iiif_final_dir).and_return(@iiif_final_dir)
        end

        after(:each) do
          FileUtils.rm_rf(@iiif_final_dir)
        end

        it 'tileizes images and copies TXT files' do
          output_dir = File.join(@iiif_final_dir, directory).tap { |dir| FileUtils.mkdir(dir) }

          iiif_item = IIIFItem.create_from(source_dir, output_dir, title: 'Pamphlet', author: 'Canada. Department of Agriculture.')

          expect(iiif_item).not_to be_nil
          iiif_dir = iiif_item.dir_path
          expect(iiif_dir.parent.to_s).to eq(iiif_final_dir)
          expect(iiif_dir.basename.to_s).to eq(directory)

          source_entries = Dir.entries(source_dir)
          expected_tiffs = source_entries.select { |e| e.end_with?('.tif') }
          expected_txts = source_entries.select { |e| e.end_with?('.txt') }

          pages = iiif_item.pages
          expect(pages.size).to eq(expected_tiffs.size)
          actual_tiffs = pages.map(&:basename).map(&:to_s)
          actual_texts = pages.map { |p| p.txt_path&.basename&.to_s }

          expect(actual_tiffs).to match_array(expected_tiffs)
          expect(actual_texts).to match_array(expected_txts)
        end
      end

    end
  end
end
