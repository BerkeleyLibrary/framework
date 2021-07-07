require 'ucblit/marc'
require 'ucblit/logging'
require 'lending/tileizer'
require 'lending/path_utils'

module Lending
  class Processor
    include UCBLIT::Logging

    attr_reader :ready_dir, :final_dir, :record_id, :barcode, :marc_path

    def initialize(ready_dir, final_dir)
      @ready_dir = PathUtils.ensure_dirpath(ready_dir)
      @final_dir = PathUtils.ensure_dirpath(final_dir)
      @record_id, @barcode = PathUtils.decompose_dirname(@ready_dir)

      raise ArgumentError, "#{ready_dir}: MARC record not found" unless (@marc_path = find_marc_path)
    end

    def author
      @author ||= clean_value(find_author)
    end

    def title
      @title ||= clean_value(find_title)
    end

    def marc_record
      @marc_record ||= MARC::XMLReader.read(marc_path.to_s, freeze: true).first
    end

    def process!
      tileize_images!
      copy_ocr_text!
      write_manifest!
      # TODO: create database record?
    end

    # TODO: verify

    private

    def tileize_images!
      Tileizer.tileize_all(ready_dir, final_dir)
    end

    def copy_ocr_text!
      output_images.each do |output_img_path|
        output_txt_path = Lending::PathUtils.txt_path_from(output_img_path)
        next unless (input_text_path = ready_dir.join(output_txt_path.basename)).exist?

        logger.info("Copying #{input_text_path} to #{output_txt_path}")
        FileUtils.cp(input_text_path.to_s, output_txt_path.to_s)
      end
    end

    def output_images
      final_dir.children(false).select { |c| Lending::PathUtils.tiff_ext?(c) }
    end

    def write_manifest!
      manifest = IIIFManifest.new(title: title, author: author, dir_path: final_dir)
      manifest.write_manifest_erb!
    end

    def find_title
      title_df = find_tag('245')
      return unless title_df

      %w[a b].map { |code| title_df[code] }.join(' ')
    end

    def find_author
      author_df = find_tag('100') || find_tag('110') || find_tag('710')
      return unless author_df

      %w[a b].map { |code| author_df[code] }.join(' ')
    end

    def find_tag(tag)
      data_fields_by_tag[tag]&.first
    end

    def clean_value(v)
      v.sub(/[,:; ]+$/, '')
    end

    def data_fields_by_tag
      @data_fields_by_tag ||= marc_record.data_fields_by_tag
    end

    def find_marc_path
      marc_path = ready_dir.join('marc.xml')
      return marc_path if marc_path.exist?

      marc_path = ready_dir.join("#{record_id}.xml")
      return marc_path if marc_path.exist?
    end
  end
end
