require 'berkeley_library/tind'
require_relative 'asset_file'
require 'nokogiri'

module TindMarc
  class AlmaTind
    BerkeleyLibrary::Alma::Config.default!

    # rubocop:disable Metrics/ParameterLists
    def setup_collection(tag_336, tag_852, tag_980, tag_982_a, tag_982_b, tag_991)
      BerkeleyLibrary::TIND::Mapping::AlmaBase.collection_parameter_hash = {
        '336' => [tag_336],
        '852' => [tag_852],
        '980' => [tag_980],
        '982' => [tag_982_a, tag_982_b],
        '991' => tag_991
      }
    end
    # rubocop:enable Metrics/ParameterLists

    def add_fft(files, url_base, fields)
      files.each do |file|
        field_fft = ::MARC::DataField.new('FFT', ' ', ' ', ['a', "#{url_base}#{File.basename(file)}"], ['d', File.basename(file)])
        fields << field_fft
      end
      fields
    end

    def additional_tind_fields(key, files, url_base, field_980a, rights = nil)
      fields = []

      field_035 = ::MARC::DataField.new('035', ' ', ' ', ['a', "(#{field_980a})#{key}"])
      fields << field_035

      unless rights.nil?
        field_540 = ::MARC::DataField.new('540', ' ', ' ', ['a', rights])
        fields << field_540
      end

      field_902 = ::MARC::DataField.new('902', ' ', ' ', %w[d #{Date.today.to_s}], %w[n syscript])
      fields << field_902

      add_fft(files, url_base, fields)
    end

  end
end
