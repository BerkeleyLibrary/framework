require 'lending/path_utils'

module Lending
  class MarcMetadata
    attr_reader :marc_path

    def initialize(marc_path)
      @marc_path = PathUtils.ensure_filepath(marc_path)
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

    private

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

  end
end
