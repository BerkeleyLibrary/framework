require 'berkeley_library/tind'
require 'net/https'
require 'openssl'


module TindMarcSecondary
  class TindVerification
    attr_reader :tind_field_035_value

    def initialize(mmsid)
      @mms_id = mmsid
    end

    # def verify_tind
    #   url = 'https://digicoll.lib.berkeley.edu/search?ln=en&cc=Map+Collections&p=901:991062534449706532&of=xm'
    #   response = Faraday.get(url)
    #   Rails.logger.info("myturn1: #{response.body}")
    #   records = TIND::Mapping::Util.from_xml(response.body)
    #   Rails.logger.info("myturn: #{records.first.inspect}")
    #   records
    # end

    def verify_tind
      url = 'https://digicoll.lib.berkeley.edu/search?In=en&c=Map+Collections&p=901:991000401929706532&&of=xm&ot=035'
      # url = 'https://digicoll.lib.berkeley.edu/search?In=en&c=Map+Collections&p=901:991000401929706532&&of=xm'
      initheaders = {}

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Get.new(uri.request_uri, initheaders)
      
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      
      response = http.request(req)
      # puts response.body
      # s = '\"YYCHHme\n'
      # Rails.logger.info(s)
      # Rails.logger.info("myturn2: #{response.body}")
      # tt = '<collection> <record>\n  <controlfield tag=\"001\">281446</controlfield>\n  <datafield tag=\"035\" ind1=\" \" ind2=\" \">\n    <subfield code=\"a\">aerialphotos-991000401929706532</subfield>\n  </datafield>\n</record>\n\n</collection>'
      Rails.logger.info("starting TIND mappings")
      content = response.body
      records = BerkeleyLibrary::TIND::Mapping::Util.from_xml(content)
      # Rails.logger.info("myturn: #{records.first.inspect}")
      # records.first.
      # records
      puts records.class.name
      Rails.logger.info("ending TIND mappings")
      val = f_035_value(records)
      Rails.logger.info("035!! #{val}")
      val


      # marc_xml = BerkeleyLibrary::TIND::API.get(:search, c: 'Map+Collections')
      # Rails.logger.info("myturn1: #{marc_xml}")

      # url = 'https://digicoll.lib.berkeley.edu/search?'
      # params = { ln: 'en', cc: 'Map+Collections', p: '901:991062534449706532', of: 'xm' }
      # conn = Faraday.new(url)
      # response = conn.get('', params)
      # Rails.logger.info("myturn1: #{response.body}")
      # records = TIND::Mapping::Util.from_xml(response.body)
      # Rails.logger.info("myturn: #{records.first.inspect}")
      # records
    end

    private

    def f_035_value(record)
      record['035']['a']
    end

  end
end
