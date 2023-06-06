module AlmaServices

  module Base
    include BerkeleyLibrary::Util

    def alma_api_url
      Rails.application.config.alma_api_url
    end

    def alma_api_key(env = 'production')
      env == 'production' ? Rails.application.config.alma_api_key : Rails.application.config.alma_sandbox_key
    end

    def user_uri_for(alma_user_id)
      URIs.append(alma_api_url, 'users', alma_user_id)
    end

    def connection(env = 'production')
      Faraday.new do |faraday|
        faraday.request(:url_encoded)
        faraday.headers['Accept'] = 'application/json'
        faraday.headers['Authorization'] = "apikey #{alma_api_key(env)}"

        inject_log_middleware(faraday) unless Rails.env.production?
      end
    end

    private

    def inject_log_middleware(f)
      f.response(:logger, Rails.logger, { headers: true, bodies: true, errors: true })
    end

  end

  class Patron
    class << self
      include Base

      def authenticate_alma_patron(alma_user_id, alma_password)
        # Alma requires these params to be in the query string
        params = { op: 'auth', view: 'full', password: alma_password }
        auth_uri = URIs.append(user_uri_for(alma_user_id), '?', URI.encode_www_form(params))

        res = connection.post(auth_uri, params)
        res.success?
      end

      # expand=fees is added since the default response is nil for fees
      def get_user(alma_user_id)
        params = { view: 'full', expand: 'fees' }
        connection.get(user_uri_for(alma_user_id), params).tap do |res|
          raise ActiveRecord::RecordNotFound, "Alma query failed with response: #{res.status}" unless res.status == 200
        end
      end

      def save(alma_user_id, user)
        # noinspection RubyArgCount
        connection.put(user_uri_for(alma_user_id), user.to_json, { 'Content-Type' => 'application/json' }).tap do |res|
          raise ActiveRecord::RecordNotFound, 'Failed to save.' unless res.status == 200
        end

        'Saved user.' # TODO: what is this for?
      end

      def valid_proxy_patron?(alma_id)
        res = get_user(alma_id)
        ValidProxyPatron.valid?(JSON.parse(res.body))
      end

    end
  end

  class Fines
    class << self
      include Base

      def fees_uri_for(alma_id)
        URIs.append(user_uri_for(alma_id), 'fees')
      end

      def fee_uri_for(alma_id, fee_id)
        URIs.append(fees_uri_for(alma_id), fee_id)
      end

      def fetch_all(alma_user_id)
        res = connection.get(fees_uri_for(alma_user_id))
        raise ActiveRecord::RecordNotFound, 'No fees could be found.' unless res.status == 200

        JSON.parse(res.body)
      end

      # If you pay the full amount owed for a fee, it automatically changes the status to "CLOSED"
      def credit(alma_user_id, pp_ref_number, fine)
        # Alma requires these params to be in the query string
        params = { op: 'pay', method: 'ONLINE', amount: fine.balance, external_transaction_id: pp_ref_number }
        payment_uri = URIs.append(fee_uri_for(alma_user_id, fine.id), '?', URI.encode_www_form(params))

        connection.post(payment_uri).tap do |res|
          raise ActiveRecord::RecordNotFound, "Alma query failed with response: #{res.status}" unless res.status == 200
        end
      end
    end
  end

  # An "ItemSet" is a collection of members, which are references to items.
  class ItemSet

    class << self
      include Base

      def fetch_sets(env, offset = 0)
        params = {
          view: 'full',
          expand: 'none',
          limit: 100,
          content_type: 'ITEM',
          offset:
        }

        res = connection(env).get(URIs.append(alma_api_url, 'conf/sets'), params)
        raise ActiveRecord::RecordNotFound, 'No item sets could be found..' unless res.status == 200

        JSON.parse(res.body)
      end

      def fetch_set(env, id)
        res = connection(env).get(URIs.append(alma_api_url, "conf/sets/#{id}"))
        raise ActiveRecord::RecordNotFound, "No set with ID #{id} found..." unless res.status == 200

        JSON.parse(res.body)
      end

      def fetch_members(set_id, env, offset = 0)
        params = {
          offset:,
          limit: 100
        }
        res = connection(env).get(URIs.append(alma_api_url, "conf/sets/#{set_id}/members"), params)
        raise ActiveRecord::RecordNotFound, 'No item sets could be found.' unless res.status == 200

        JSON.parse(res.body)
      end

      def fetch_item(env, mms_id, holding_id, item_pid)
        uri = URIs.append(alma_api_url, "bibs/#{mms_id}/holdings/#{holding_id}/items/#{item_pid}")
        res = connection(env).get(uri)
        raise ActiveRecord::RecordNotFound, 'Item could be found.' unless res.status == 200

        JSON.parse(res.body)
      end

      def save_item(item)
        uri = URIs.append(alma_api_url, "bibs/#{item.mms_id}/holdings/#{item.holding_id}/items/#{item.item_pid}")
        item_ids = "#{item.mms_id}|#{item.holding_id}|#{item.item_pid}"

        connection(item.env).put(uri, item.to_json, { 'Content-Type' => 'application/json' }).tap do |res|
          Rails.logger.warn("Failed to save item: #{item_ids}") unless res.status == 200
        end
      end
    end
  end

  class Marc
    class << self
      def record(id)
        record_id = BerkeleyLibrary::Alma::RecordId.parse(id)
        return unless record_id

        record_id.get_marc_record
      end
    end
  end
end
