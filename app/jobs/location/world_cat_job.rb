module Location
  class WorldCatJob < LocationJobBase
    include BerkeleyLibrary::Location::WorldCat

    # Finds unprocessed HathiTrust records for the specified request, retrieves
    # the WorldCat holdings for each, and updates the records accordingly.
    #
    # @param location_request [LocationRequest] the request
    def perform(location_request)
      raise ArgumentError, "Not a WorldCat holdings request: #{location_request.id}" unless location_request.world_cat?

      search_wc_symbols = location_request.search_wc_symbols
      pending_wc_records(location_request).find_each do |wc_record|
        update_record(wc_record, search_wc_symbols)
      end
    end

    private

    def update_record(wc_record, search_wc_symbols)
      holdings = retrieve_holdings(wc_record.oclc_number, search_wc_symbols)
      wc_record.update(wc_retrieved: true, wc_symbols: holdings.join(','))
    rescue StandardError => e
      log_error(e)
      wc_record.update(wc_retrieved: true, wc_error: e.message)
    end

    def retrieve_holdings(oclc_number, search_wc_symbols)
      req = LibrariesRequest.new(oclc_number, symbols: search_wc_symbols)
      begin
        req.execute
      rescue RestClient::Exception => e
        logger.warn("GET #{req.uri} failed with #{e.message}")
        raise
      end
    end

    # Gets the pending WorldCat records for the specified request
    #
    # @param location_request [LocationRequest] the request
    # @return ActiveRecord::Relation the records for which holdings have not yet been retrieved
    def pending_wc_records(location_request)
      location_request
        .location_records
        .where(wc_retrieved: false)
    end
  end
end
