require 'ucblit/marc'
require 'ucblit/logging'
require 'lending/tileizer'
require 'lending/path_utils'

module Lending
  class Processor
    include UCBLIT::Logging

    attr_reader :indir, :outdir, :record_id, :barcode, :marc_path

    def initialize(indir, outdir)
      @indir = PathUtils.ensure_dirpath(indir)
      @outdir = PathUtils.ensure_dirpath(outdir)
      @record_id, @barcode = PathUtils.decompose_dirname(@indir)

      raise ArgumentError, "#{indir}: MARC record not found" unless (@marc_path = find_marc_path)
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
      Tileizer.tileize_all(indir, outdir)
    end

    def copy_ocr_text!
      input_txts.each do |input_txt|
        output_txt = outdir.join(input_txt.basename)
        logger.info("Copying #{input_txt} to #{output_txt}")
        FileUtils.cp(input_txt.to_s, output_txt.to_s)
      end
    end

    def input_txts
      @input_txts ||= indir.children.filter_map do |p|
        next unless PathUtils.image_ext?(p)

        txt_path = PathUtils.txt_path_from(p)
        txt_path if txt_path.exist?
      end
    end

    def write_manifest!
      manifest = IIIFManifest.new(title: title, author: author, dir_path: outdir)
      manifest.write_manifest_erb!
    end

    def find_title
      df = find_tag('245')
      return unless df

      join_subfields(df, %w[a b])
    end

    def find_author
      df = find_tag('100') || find_tag('110') || find_tag('710')
      return unless df

      join_subfields(df, %w[a b])
    end

    def join_subfields(df, codes)
      codes.map { |code| df[code] }.compact.map(&:strip).join(' ')
    end

    def find_tag(tag)
      data_fields_by_tag[tag]&.first
    end

    def clean_value(v)
      v.strip.sub(%r{[ ,/:;]+$}, '')
    end

    def data_fields_by_tag
      @data_fields_by_tag ||= marc_record.data_fields_by_tag
    end

    def find_marc_path
      marc_stems = ['marc', record_id.downcase]

      indir.children.find do |p|
        PathUtils.xml_ext?(p) && marc_stems.include?(PathUtils.stem(p).downcase)
      end
    end
  end
end
