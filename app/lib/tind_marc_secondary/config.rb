module TindMarcSecondary
  Config = Struct.new(:incoming_path,
                      :da_batch_path,
                      :da_label_file_path,
                      :base_url,
                      :prefix_035,
                      :collection_subfields_tobe_updated,
                      :collection_fields,
                      :verify_tind) do
    def display
      "incoming_path: #{incoming_path},
       da_batch_path: #{da_batch_path},
       da_label_file_path: #{da_label_file_path},
       base_url: #{base_url},
       prefix_035: #{prefix_035},
       collection_subfields_tobe_updated: #{collection_subfields_tobe_updated},
       collection_fields: #{collection_fields},
       verify_tind: #{verify_tind}"
    end
  end

end
