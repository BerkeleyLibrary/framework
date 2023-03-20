module Holdings
  class WorldCatJob < ApplicationJob
    include BerkeleyLibrary::Holdings::WorldCat

    # Finds unprocessed HathiTrust records for the specified task, retrieves
    # the WorldCat holdings for each, and updates the records accordingly.
    #
    # @param holdings_task [HoldingsTask] the task
    def perform(holdings_task)
      search_wc_symbols = holdings_task.search_wc_symbols
      pending_wc_records(holdings_task).find_each do |wc_record|
        update_record(wc_record, search_wc_symbols)
      end
    end

    private

    def update_record(wc_record, search_wc_symbols)
      holdings = retrieve_holdings(wc_record.oclc_number, search_wc_symbols)
      wc_record.update(retrieved: true, wc_symbols: holdings.join(','))
    rescue StandardError => e
      log_error(e)
      wc_record.update(retrieved: true, wc_error: e.message)
    end

    def retrieve_holdings(oclc_number, search_wc_symbols)
      req = LibrariesRequest.new(oclc_number, symbols: search_wc_symbols)
      req.execute
    end

    # Gets the pending WorldCat records for the specified task
    #
    # @param holdings_task [HoldingsTask] the task
    # @return ActiveRecord::Relation the records for which holdings have not yet been retrieved
    def pending_wc_records(holdings_task)
      holdings_task
        .holdings_world_cat_records
        .where(retrieved: false)
    end
  end
end
