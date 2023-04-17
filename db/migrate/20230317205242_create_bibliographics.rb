class CreateBibliographics < ActiveRecord::Migration[7.0]
  def change
    create_table :host_bib_tasks do |t|     
      t.string :filename, null: false
      t.string :email
      t.integer :status
      t.timestamps
    end

    create_table :host_bibs do |t|
      t.string :mms_id
      t.integer :marc_status
      t.references :host_bib_task, null: false, foreign_key: true
      t.datetime :updated_at
    end

    create_table :linked_bibs do |t|
      t.string :mms_id
      t.integer :marc_status
      t.string :ldr_6
      t.string :ldr_7
      t.string :field_035     
    end

    create_table :host_bib_linked_bibs do |t|
      t.references :host_bib, null: false, foreign_key: true
      t.references :linked_bib, null: false, foreign_key: true      
    end

  end
end
