module TindMarcSecondary
  class TindVerfication
    attr_reader :insert_items, :append_items
    def initialize(assets)
        @collection_name = collection_name
        @ls = ls

    end

    def verify_tind
        Item = Struct.new(:folder_name, :tag_035, :file_desc_list)
        # ruturn [foler_name, f_035_a_value]
    end


    private

    def verifying_tind(mmsid)

    end

  end


end