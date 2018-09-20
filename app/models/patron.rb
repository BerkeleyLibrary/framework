require 'net/ssh'
require 'net/http'
require 'shellwords'

class Patron
  include ActiveModel::Model

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
      base_url = Rails.application.config.altmedia['patron_url']
      patron_url = URI.join(base_url, "/PATRONAPI/#{URI.escape(id)}/dump")
      res = Net::HTTP.get_response(patron_url)

      if res.kind_of?(Net::HTTPOK)
        return new_from_dump(id, res.body)
      else
        raise res
      end
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

    res = Net::SSH.start(update_url.host, update_url.user, ssh_opts) do |ssh|
      command = [update_url.path, note, id].shelljoin
      ssh.exec!(command)
    end

    unless res.match('Finished Successfully')
      raise StandardError, "Failed updating patron record for #{patron.id}"
    end
  end

  private

  def update_url
    Rails.application.config.altmedia['expect_url']
  end
end
