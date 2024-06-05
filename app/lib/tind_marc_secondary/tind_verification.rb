require 'berkeley_library/tind'
require 'net/https'
require 'openssl'

module TindMarcSecondary
  class TindVerification

    def initialize(tind_collection_name)
      @collection_name = qualified_collection_name(tind_collection_name)
    end

    # TODO: handle restrict collection
    def f_035(mmsid)
      url = tind_url(mmsid)
      initheaders = {}
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      req = Net::HTTP::Get.new(uri.request_uri, initheaders)
      response = http.request(req)
      record = BerkeleyLibrary::TIND::Mapping::Util.from_xml(response.body)
      f_035_value(record)
    end

    private

    def tind_url(mmsid)
      "#{Rails.application.config.tind_base_uri}/search?In=en&c=#{@collection_name}&p=901:#{mmsid}&of=xm&ot=035"
    end

    def f_035_value(record)
      return unless record

      record['035']['a']
    end

    def qualified_collection_name(tind_collection_name)
      tind_collection_name.split.compact.join('+')
    end

  end
end
