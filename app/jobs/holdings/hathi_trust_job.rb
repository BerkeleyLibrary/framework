module Holdings
  class HathiTrustJob < HoldingsJobBase
    include BerkeleyLibrary::Holdings::HathiTrust

    # Finds unprocessed HathiTrust records for the specified task, retrieves
    # the record URLs for each, and updates the records accordingly.
    #
    # @param holdings_task [HoldingsTask] the task
    def perform(holdings_task)
      raise ArgumentError, "Not a HathiTrust holdings task: #{holdings_task.id}" unless holdings_task.hathi?

      each_batch_for(holdings_task) do |batch|
        process_batch(batch)
      end
    end

    private

    # Gets the pending HathiTrust records for the specified task
    #
    # @param holdings_task [HoldingsTask] the task
    # @return ActiveRecord::Relation the records for which URLs have not yet been retrieved
    def pending_ht_records(holdings_task)
      holdings_task
        .holdings_records
        .where(ht_retrieved: false)
    end

    # Finds unprocessed HathiTrust records for the specified task and yields them
    # in batches suitable for {{RecordUrlBatchRequest}}.
    #
    # @param holdings_task [HoldingsTask] the task to process records for.
    # @yield batch [Array<HoldingsHathiTrustRecord>] each batch of records to process.
    def each_batch_for(holdings_task, &)
      batch_size = RecordUrlBatchRequest::MAX_BATCH_SIZE
      pending_ht_records(holdings_task)
        .find_in_batches(batch_size:, &)
    end

    # Processes the specified batch of records.
    #
    # @param batch [Array<HoldingsHathiTrustRecord>] the batch of records to process.
    def process_batch(batch)
      ht_record_urls = retrieve_record_urls(batch)
      update_ht_record_urls(batch, ht_record_urls)
    rescue StandardError => e
      log_error(e)
      update_ht_errors(batch, e.message)
    end

    # Retrieves the record URLs.
    #
    # @param batch [Array<HoldingsHathiTrustRecord>] the batch of records to retrieve URLs for.
    # @return Hash<String, String> a hash mapping OCLC numbers to record URLs
    def retrieve_record_urls(batch)
      oclc_numbers = batch.map(&:oclc_number)
      req = RecordUrlBatchRequest.new(oclc_numbers)
      req.execute
    end

    # Marks the specified batch of records as retrieved, and sets the `ht_error` message.
    #
    # @param batch [Array<HoldingsHathiTrustRecord>] the batch of records to update.
    # @param err_msg [String]
    def update_ht_errors(batch, err_msg)
      batch.each do |record|
        record.update(ht_retrieved: true, ht_error: err_msg)
      end
    end

    # Marks the specified batch of records as retrieved, and sets the `ht_record_url`
    # (if present in the specified hash, `nil` otherwise).
    #
    # @param batch [Array<HoldingsHathiTrustRecord>] the batch of records to update.
    # @param ht_record_urls [Hash<String, String>] a hash mapping OCLC numbers to record URLs.
    def update_ht_record_urls(batch, ht_record_urls)
      batch.each do |record|
        ht_record_url = ht_record_urls[record.oclc_number]
        record.update(ht_retrieved: true, ht_record_url:)
      end
    end
  end
end
