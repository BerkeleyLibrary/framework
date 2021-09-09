module AlmaServices
  class Patron

    def self.authenticate_alma_patron(alma_id, alma_password)
      req = "#{Config.alma_api_url}users/#{alma_id}?op=auth&password=#{alma_password}&view=full&apikey=#{Config.alma_api_key}"
      res = Faraday.post(req, {}, 'Accept' => 'application/json')
      res.success?
    end

    # expand=fees is added since the default response is nil for fees
    def self.get_user(alma_id)
      req = "#{Config.alma_api_url}users/#{alma_id}?view=full&expand=fees&apikey=#{Config.alma_api_key}"
      res = Faraday.get(req, {}, 'Accept' => 'application/json')
      raise ActiveRecord::RecordNotFound, "Alma query failed with response: #{res.status}" unless res.status == 200

      res
    end

    def self.valid_proxy_patron?(alma_id)
      res = get_user(alma_id)
      ValidProxyPatron.valid?(JSON.parse(res.body))
    end

  end

  class Fines
    def self.fetch_all(alma_user_id)
      req = "#{Config.alma_api_url}users/#{alma_user_id}/fees?apikey=#{Config.alma_api_key}"
      res = Faraday.get(req, {}, 'Accept' => 'application/json')
      raise ActiveRecord::RecordNotFound, 'No fees could be found.' unless res.status == 200

      JSON.parse(res.body)
    end

    def self.credit(alma_user_id, pp_ref_number, fine)
      # If you pay the full amount owed for a fee, it automatically changes the status to "CLOSED"
      req = "#{Config.alma_api_url}users/#{alma_user_id}/fees/#{fine.id}?apikey=#{Config.alma_api_key}&op=pay&amount=#{fine.balance}
      &method=ONLINE&external_transaction_id=#{pp_ref_number}"

      res = Faraday.post(req, {}, 'Accept' => 'application/json')
      raise ActiveRecord::RecordNotFound, "Failed to credit fee #{fee_id}" unless res.status == 200
    end
  end

  class Config
    def self.alma_api_url
      Rails.application.config.alma_api_url
    end

    def self.alma_api_key
      Rails.application.config.alma_api_key
    end
  end
end
