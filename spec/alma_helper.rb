require 'webmock'

# NOTE: totally-fake-key is set in forms_helper.rb
def stub_patron_dump(patron_id, status: 200, alma_api_key: 'totally-fake-key', body: nil)
  patron_dump_url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{patron_id}?&expand=fees&view=full"

  stub_request(:get, patron_dump_url)
    .with(headers: { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" })
    .to_return(
      status:,
      body: body || begin
        body_file = "spec/data/alma_patrons/#{patron_id}.json"
        raise IOError, "No such file: #{body_file}" unless File.file?(body_file)

        File.new(body_file)
      end
    )
end

def stub_patron_save(patron_id, updated_patron, alma_api_key: 'totally-fake-key')
  patron_save_url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/#{patron_id}"
  stub_request(:put, patron_save_url)
    .with(body: /#{Regexp.escape(updated_patron)}/)
    .with(headers: { 'Accept' => 'application/json', 'Authorization' => "apikey #{alma_api_key}" })
    .to_return(status: 200, body: '', headers: {})
end

def all_alma_ids
  Dir.entries('spec/data/alma_patrons').grep(/[0-9]+\.json/).map { |f| f.match(/([0-9]+)/)[0] }
end

# Extension methods for Patron module and Alma::Type class, used only in test
module Alma

  FRAMEWORK_ADMIN_ID = '013191304'.freeze
  NON_FRAMEWORK_ADMIN_ID = '3032640236'.freeze

  # Sample IDs corresponding to spec/data/calnet and spec/data/alma_patrons
  SAMPLE_IDS = {
    Alma::Type::UNDERGRAD => '99999997',
    Alma::Type::UNDERGRAD_SLE => NON_FRAMEWORK_ADMIN_ID,
    Alma::Type::GRAD_STUDENT => '18273645',
    Alma::Type::FACULTY => '12345678',
    Alma::Type::MANAGER => '5551213',
    Alma::Type::LIBRARY_STAFF => FRAMEWORK_ADMIN_ID,
    Alma::Type::STAFF => '5551212',
    Alma::Type::POST_DOC => '99999891',
    Alma::Type::VISITING_SCHOLAR => '87651234',
    Alma::Type::EXTENSION_STUDENT => '12345679',
    Alma::Type::UCB_ACAD_AFFILIATE => '12345699'
  }.freeze

  class Type
    class << self
      def name_of(code)
        const = Type.constants.find { |c| Type.const_get(c) == code }
        const.to_s if const
      end

      def all
        Type.constants.map { |const| Type.const_get(const) }
      end

      def sample_id_for(code)
        sample_id = Alma::SAMPLE_IDS[code]
        raise ArgumentError, "No sample ID for patron type #{name_of(code)}" unless sample_id

        sample_id
      end
    end
  end
end
