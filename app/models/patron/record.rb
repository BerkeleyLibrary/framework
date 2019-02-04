require 'net/ssh'
require 'open-uri'
require 'shellwords'

module Patron
  # Represents a patron record pulled from oskicat's PATRONAPI
  #
  # @see https://dev-oskicatp.berkeley.edu:54620/PATRONAPI/012158720/dump Sample Record
  class Record
    include ActiveModel::Model

    # Base URL for the Patron API.
    #
    # @return [URI]
    class_attribute :api_base_url, default: URI.parse(
      "https://dev-oskicatp.berkeley.edu:54620/PATRONAPI/"
    )

    # URL of the expect script used to add notes to patron records
    #
    # @return [URI]
    class_attribute :expect_url, default: URI.parse(
      "ssh://altmedia@vm161.lib.berkeley.edu/home/altmedia/bin/mkcallnote"
    )

    # The patron's affiliation code (UC Berkeley, Community College, etc.)
    #
    # See Patron::Affiliation for a partial list of affiliate codes.
    #
    # @return [String]
    attr_accessor :affiliation

    # The patron's manual blocks, or `nil` if there are none
    #
    # @return [String, nil]
    attr_accessor :blocks

    # The patron's email address on file
    #
    # @return [String]
    attr_accessor :email

    # The patron ID (employee, student, faculty, etc. -- can be a lot of things)
    #
    # @return [String]
    attr_accessor :id

    # The patron's name, usually in the form "LAST,FIRST"
    #
    # @return [String]
    attr_accessor :name

    # The patron's type code (undergraduate, post-doc, faculty, etc.)
    #
    # See Patron::Type for a partial list of codes.
    #
    # @return [String]
    attr_accessor :type

    # An optional note in the patron record, i.e. an indication that he/she is book scan eligible
    #
    # @return [String]
    attr_accessor :note

    class << self
      # Returns the patron record for a given ID, or nil if it is not found
      #
      # @return [Patron, nil]
      #
      # @raise [Error::PatronApiError] If an error occurs contacting
      #   the Patron API (commonly due to firewall issues) or if the API returns
      #   an unknown error message.
      def find(id)
        # Fetch raw data from the Patron API
        url = URI.join(self.api_base_url, "/PATRONAPI/#{URI.escape(id)}/dump")
        opts = { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE }
        data = parse_dump(open(url, opts).read)

        # Handle errors
        if data["ERRMSG"].present?
          return nil if data["ERRMSG"] == "Requested record not found"
          raise PatronApiError, data["ERRMSG"]
        end

        # Initialize new patron record object from the parsed data
        self.new(
          id: id,
          affiliation: data['PCODE1[p44]'],
          blocks: data['MBLOCK[p56]'] == '-' ? nil : data['MBLOCK[p56]'],
          email: data['EMAIL ADDR[pz]'],
          name: data['PATRN NAME[pn]'],
          type: data['P TYPE[p47]'],
          note: data['NOTE[px]'],
        )
      rescue OpenURI::HTTPError => e
        raise Error::PatronApiError
      end

      private

      # Parses patron attributes from a raw PATRONAPI response
      def parse_dump(dumpstr)
        data = {}
        ActionController::Base.helpers.strip_tags(dumpstr).each_line do |line|
          if matches = line.match(/^(?<key>[\/\w\s]+(\[.+\]+)?)=(?<val>.*)$/)
            key, val = matches[:key], matches[:val]

            if data.include?(key) # multivalued field
              data[key] = [data[key]] unless data[key].kind_of?(Array)
              data[key] << val
            else
              data[key] = val
            end
          end
        end
        return data
      end
    end

    # Adds a note to the patron's record
    #
    # This uses the super-hacky method of executing an expect script over SSH
    # in order to perform the update. That means the application needs SSH
    # access to the user running that script. This is typically handled by,
    # simply, adding a valid authorized key to the application user's ~/.ssh.
    #
    # @param [String] note the note to add
    #
    # @todo It would be great to pull the update logic into our application,
    #   rather than relying on the expect script. That would be much more
    #   robust and easier to test/monitor/verify.
    def add_note(note)
      Rails.logger.debug "Updating patron record: #{id}"

      ssh_opts = {
        non_interactive: true,
      }

      res = Net::SSH.start(expect_url.host, expect_url.user, ssh_opts) do |ssh|
        command = [expect_url.path, note, id].shelljoin
        ssh.exec!(command)
      end

      unless res.match('Finished Successfully')
        raise StandardError, "Failed updating patron record for #{patron.id}"
      end
    end
  end
end
