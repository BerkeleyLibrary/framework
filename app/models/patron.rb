require 'net/ssh'
require 'open-uri'
require 'shellwords'

class Patron
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

  attr_accessor(
    :affiliation,
    :blocks,
    :email,
    :id,
    :name,
    :type,
  )

  class << self
    def find(id)
      url = URI.join(self.api_base_url, "/PATRONAPI/#{URI.escape(id)}/dump")
      opts = { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE }
      new_from_dump(id, open(url, opts).read)
    rescue OpenURI::HTTPError => e
      raise Framework::Errors::PatronApiError
    end

    def new_from_dump(id, dumpstr)
      data = parse_dump(dumpstr)

      err = data["ERRMSG"]

      if err.nil?
        return new(
          id: id,
          affiliation: data['PCODE1[p44]'],
          blocks: data['MBLOCK[p56]'] == '-' ? nil : data['MBLOCK[p56]'],
          email: data['EMAIL ADDR[pz]'],
          name: data['PATRN NAME[pn]'],
          type: data['P TYPE[p47]'],
        )
      end

      return nil if err == "Requested record not found"

      raise Exception, err
    end

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
