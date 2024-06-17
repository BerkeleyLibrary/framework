require 'berkeley_library/tind'
require 'net/https'
require 'openssl'
require 'json'
require 'nokogiri'

module TindMarcSecondary
  class TindVerification

    # url = 'https://digicoll.lib.berkeley.edu/search?In=en&p=901:991024141319706532&of=xm&ot=035'
    # url = 'https://digicoll.lib.berkeley.edu/api/v1/search?In=en&p=901:991024141319706532&of=xm&ot=001,035,245'
    # url = 'https://digicoll.lib.berkeley.edu/api/v1/record/281845/?of=xm&ot=001,035,245'
    # "{\"reason\": \"Failed to validate given credentials\", \"success\": false}"
    # {\"hits\": [281845], \"total\": 1}"
    def initialize; end

    def f_035(mmsid)
      # mmsid = 'a991042697829706532'
      id = record_id(mmsid)
      return if id.nil?

      record = marc_xml_record(id)
      f_035_value(record)
    end

    private

    def response(url)
      initheaders = { 'Authorization' => "Token #{Rails.application.config.tind_api_key}" }
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      req = Net::HTTP::Get.new(uri.request_uri, initheaders)
      http.request(req)
    rescue StandardError => e
      Rails.logger.error("Error fetching TIND record: #{e.message}")
    end

    # Tind api search response code is '200' when searching on a field value and has no records found
    def record_id(mmsid)
      url = tind_api_mmsid_url(mmsid)
      response = response(url)
      code = response.code
      raise StandardError, "Error fetching TIND record on mmsid: #{response.message}" unless code == '200'

      hash = JSON.parse(response.body)
      count = hash['total']
      raise StandardError, "Multiple TIND records found for mmsid: #{mmsid}" if count > 1
      return if count == 0

      hash['hits'][0]
    end

    # Tind api search response code is '404' when searching on a field value and has no records found
    def marc_xml_record(record_id)
      url = tind_api_record_id_url(record_id)
      response = response(url)
      code = response.code
      raise StandardError, "Error fetching TIND record with id #{record_id}: #{response.message}" unless %w[200 404].include?(code)

      return if code == 404

      response.body
      Nokogiri::XML(response.body)
    end

    def tind_api_record_id_url(record_id)
      "#{Rails.application.config.tind_base_uri}api/v1/record/#{record_id}/?of=xm"
    end

    def tind_api_mmsid_url(mmsid)
      "#{Rails.application.config.tind_base_uri}api/v1/search?In=en&p=901:#{mmsid}&of=xm"
    end

    def f_035_value(doc)
      return unless doc

      xml_field(doc, '035', 'a')
    end

    def xml_field(doc, field, subfield)
      value = doc.xpath("//datafield[@tag='#{field}']/subfield[@code='#{subfield}']").first
      value ? value.text : nil
    end

  end
end
