module TindMarc

  class TindCollectionInfo
    def initialize(args)
      @args = args
    end

    def parameter_hash
      {
        '336' => [''],
        '852' => [''],
        '980' => [''],
        '982' => ['', ''],
        '991' => []
      }
    end

    def new_fields
      [
        create_field(:f_540_a, '540', 'a'),
        create_field_902,
        create_field(:restriction, '991', 'a')
      ].compact
    end

    def subfields_tobe_updated
      {
        '336' => { 'a' => @args[:resource_type] },
        '852' => { 'c' => @args[:library] },
        '980' => { 'a' => @args[:f_980_a] },
        '982' => f_982

      }
    end

    def prefix_035
      @args[:f_980_a] == 'Map Collections' ? "(#{prefix(@args[:f_982_a])})" : "(#{prefix(@args[:f_980_a])})"
    end

    private

    def create_field(sym, tag, sf)
      return if @args[sym].blank?

      ::MARC::DataField.new(tag, ' ', ' ', [sf, @args[sym]])
    end

    def create_field_902
      ::MARC::DataField.new('902', ' ', ' ', %w[d #{Date.today.to_s}], ['n', "syscript - #{@args[:initials]}"])
    end

    def prefix(value)
      value.gsub(' ', '_').downcase
    end

    def f_982
      hash = { 'a' => @args[:f_982_a],
               'b' => @args[:f_982_b] }
      return hash if @args[:f_982_p].empty?

      hash['p'] = @args[:f_982_p]
      hash
    end

  end
end
