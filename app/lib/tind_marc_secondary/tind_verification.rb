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

    def initialize; end

    def f_035(mmsid)
      id = record_id(mmsid)
      return if id.nil?

      record = marc_xml_record(id)
      a = f_035_value(record)
      puts "zucum"
      puts a
      a
    end

    private

    def response(url)
      a = 'Token 96de3f65-31ee-48f9-9053-5c66b2c289cf'
      initheaders = { 'Authorization' => a }
      # puts "pplease response me"
      # puts initheaders
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      req = Net::HTTP::Get.new(uri.request_uri, initheaders)
      http.request(req)
    rescue StandardError => e
      Rails.logger.error("Error fetching TIND record: #{e.message}")
    end

    # def response(url)
    #   initheaders = { 'Authorization' => "'#{Rails.application.config.tind_api_key}'" }
    #   puts "response me"
    #   puts initheaders
    #   uri = URI.parse(url)
    #   http = Net::HTTP.new(uri.host, uri.port)
    #   http.use_ssl = true
    #   http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    #   req = Net::HTTP::Get.new(uri.request_uri, initheaders)
    #   http.request(req)
    # rescue StandardError => e
    #   Rails.logger.error("Error fetching TIND record: #{e.message}")
    # end

    def record_id(mmsid)
      url = tind_api_mmsid_url(mmsid)
      # puts url
      response = response(url)

      # puts "gget record response!"
      # puts response
      hash = JSON.parse(response.body)
      # puts hash
      count = hash['total']
      raise StandardError, "Multiple TIND records found for mmsid: #{mmsid}" if count > 1
      return if count == 0

      hash['hits'][0]
    end

    # def marc_record(record_id)
    #   url = tind_api_record_id_url(record_id)
    #   response = response(url)
    #   BerkeleyLibrary::TIND::Mapping::Util.from_xml(response.body)
    # end

    def marc_xml_record(record_id)
      url = tind_api_record_id_url(record_id)
      response = response(url)
      response.body
      Nokogiri::XML(response.body)
      # puts a
      # a = BerkeleyLibrary::TIND::Mapping::Util.from_xml(response.body)
      # puts "has yzhou2"
      # puts a
      # puts 'end of has yzhou'
      # a
    end

    def tind_api_record_id_url(record_id)
      "#{Rails.application.config.tind_base_uri}/api/v1/record/#{record_id}/?of=xm"
    end

    def tind_api_mmsid_url(mmsid)
      "#{Rails.application.config.tind_base_uri}/api/v1/search?In=en&p=901:#{mmsid}&of=xm"
    end

    def f_035_value(doc)
      return unless doc

      xml_field(doc, '035', 'a')
    end

    def qualified_collection_name(tind_collection_name)
      tind_collection_name.split.compact.join('+')
    end

    def xml_field(doc, field, subfield)
      value = doc.xpath("//datafield[@tag='#{field}']/subfield[@code='#{subfield}']").first
      value ? value.text : nil
    end

  end
end
