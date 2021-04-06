module Alma
  BASE_URL = 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/'.freeze
  class Fines
    def self.fetch_all(alma_id)
      request = "#{BASE_URL}users/#{alma_id}/fees?apikey=#{ENV['ALMA_KEY']}"
      Faraday.get(request, {}, { 'Accept' => 'application/json' })
    end
  end
end
