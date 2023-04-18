class FixHoldingsRequestAttachments < ActiveRecord::Migration[7.0]

  def up
    update_record_types(from_type: 'HoldingsTask', to_type: 'HoldingsRequest')
  end

  def down
    update_record_types(from_type: 'HoldingsRequest', to_type: 'HoldingsTask')
  end

  private

  def update_record_types(from_type:, to_type:)
    sql = <<~SQL
      UPDATE active_storage_attachments 
         SET record_type = :to_type 
       WHERE record_type = :from_type
    SQL

    stmt = ActiveRecord::Base.sanitize_sql([sql, { from_type:, to_type: }])
    exec_update(stmt)
  end
end
