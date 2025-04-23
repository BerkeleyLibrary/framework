class AddCodeTToHostBibLinkedBibs < ActiveRecord::Migration[7.0]
  def change
    add_column :host_bib_linked_bibs, :code_t, :string
  end
end
