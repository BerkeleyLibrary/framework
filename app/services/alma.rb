module Alma
  BASE_URL = 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/'.freeze
  class Fines
    # By default this only queries for "ACTIVE" fees
    def self.fetch_all(alma_id)
      request = "#{BASE_URL}users/#{alma_id}/fees?apikey=#{ENV['ALMA_KEY']}"
      Faraday.get(request, {}, { 'Accept' => 'application/json' })
    end

    def self.fetch_fine(alma_id, fine_id)
      request = "#{BASE_URL}users/#{alma_id}/fees/#{fine_id}?apikey=#{ENV['ALMA_KEY']}"
      Faraday.get(request, {}, { 'Accept' => 'application/json' })
    end
    
    def self.credit_fine(alma_id, fine_id)
      # NOTE - if you pay the full amount owed for a fee, it automatically changes the status to "CLOSED"
      
      # comment (query) - optional
      # method (query) - (required if op=pay) Options are : CREDIT_CARD, ONLINE, CASH
      # amount (query) - req if pay 
      # op (query) - required - pay, waive, dispute, restore
      amount = '1.00'
      comment = 'Test2'
      paypal_id = 'NA'

      request = "#{BASE_URL}users/#{alma_id}/fees/#{fine_id}?apikey=#{ENV['ALMA_KEY']}&op=pay&amount=#{amount}&method=ONLINE&comment=#{comment}&external_transaction_id=#{paypal_id}"

      puts "\n\nREQUEST:\n>#{request}<\n\n"
      #Faraday.post(request, {}, { 'Accept' => 'application/json' })
      
    end
  end
end
