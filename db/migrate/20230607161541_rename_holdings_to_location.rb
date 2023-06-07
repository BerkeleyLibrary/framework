class RenameHoldingsToLocation < ActiveRecord::Migration[7.0]
  def up
    rename_table :holdings_requests, :location_requests
    rename_table :holdings_records, :location_records
    rename_column :location_records, :holdings_request_id, :location_request_id

    update_active_storage_attachments(from_class: 'HoldingsRequest', to_class: 'LocationRequest')
    update_good_jobs(from_name: 'Holdings', to_name: 'Location')
  end

  def down
    rename_table :location_requests, :holdings_requests
    rename_table :location_records, :holdings_records
    rename_column :holdings_records, :location_request_id, :holdings_request_id

    update_active_storage_attachments(from_class: 'LocationRequest', to_class: 'HoldingsRequest')
    update_good_jobs(from_name: 'Location', to_name: 'Holdings')
  end

  private

  def update_active_storage_attachments(from_class:, to_class:)
    sql = <<~SQL.squish
      UPDATE active_storage_attachments
         SET record_type = :to_class
       WHERE record_type = :from_class
    SQL
    stmt = ActiveRecord::Base.sanitize_sql([sql, { from_class:, to_class: }])
    exec_update(stmt)
  end

  def update_good_jobs(from_name:, to_name:)
    jsonb_replace(:good_jobs, :serialized_params, from_name:, to_name:)
    jsonb_replace(:good_job_batches, :serialized_properties, from_name:, to_name:)
    update_gj_batch_callbacks(from_name:, to_name:)
  end

  def jsonb_replace(table, column, from_name:, to_name:)
    from_name_lc, to_name_lc = [from_name, to_name].map { |n| n.downcase }

    sql = <<~SQL.squish
      UPDATE #{table}
         SET #{column} =
               REPLACE(
                 REPLACE(#{column} #>> '{}', :from_name, :to_name),  
                 :from_name_lc,
                 :to_name_lc
               )::jsonb
    SQL

    sql_args = { from_name:, to_name:, from_name_lc:, to_name_lc: }
    stmt = ActiveRecord::Base.sanitize_sql([sql, sql_args])
    exec_update(stmt)
  end

  def update_gj_batch_callbacks(from_name:, to_name:)
    from_name_lc, to_name_lc = [from_name, to_name].map { |n| n.downcase }

    sql = <<~SQL.squish
      UPDATE good_job_batches
         SET on_finish = REPLACE(
               REPLACE(on_finish, :from_name, :to_name),
               :from_name_lc,
               :to_name_lc
             ),
             on_success = REPLACE(
               REPLACE(on_success, :from_name, :to_name),
               :from_name_lc,
               :to_name_lc
             ),
             on_discard = REPLACE(
               REPLACE(on_discard, :from_name, :to_name),
               :from_name_lc,
               :to_name_lc
             )
    SQL

    sql_args = { from_name:, to_name:, from_name_lc:, to_name_lc: }
    stmt = ActiveRecord::Base.sanitize_sql([sql, sql_args])
    exec_update(stmt)
  end
end
