require 'nokogiri'
require 'open-uri'

class CampusNetwork < IPAddr
  class_attribute :lbl_networks, default: %w(
    128.3.0.0/16
    128.55.0.0/16
    131.243.0.0/16
    192.12.173.0/24
    192.58.231.0/24
    198.128.192.0/19
    198.128.24.0/21
    198.128.40.0/23
    198.128.42.0/24
    198.128.44.0/24
    198.128.52.0/24
    198.129.88.0/22
    198.129.96.0/23
    204.62.155.0/24
  )

  class_attribute :source_url, default: 'https://nettools.net.berkeley.edu/pubtools/info/campusnetworks.html'

  class << self
    def all
      get_ucb_networks + get_lbl_networks
    end

    private

    def get_ucb_networks
      raw_html = open(self.source_url).read
      parse_campus_addresses(raw_html)
    end

    def get_lbl_networks
      lbl_networks.map do |str|
        network = self.new(str)
        network.organization = :lbl
        network
      end
    end

    # Parses list of campus networks from the raw HTML IST page
    #
    # This is tightly coupled to the expected format of the nettools page (see
    # config for the URL, or the test fixtures for a sample).
    #
    # Raises RuntimeError if it fails to parse any networks, or if the structure of
    # the table changes such that the first column of the first table no longer
    # contains IP networks.
    #
    # @return [Array<IPAddr>]
    def parse_campus_addresses(raw_html)
      Nokogiri::HTML(raw_html)
        .css('#ucbito_main_container table:first') # get the first table
        .css('tr:nth-child(n+3)') # skip the two header rows
        .css('td:first') # get the first column
        .map do |node|
          node.css('strong').remove
          network = self.new(node.text)
          network.organization = :ucb
          network
        end
    end
  end

  attr_accessor :organization

  # Render as a star-formatted string
  def to_vendor_star_format
    raise "Star format doesn't work for IPv6" if ipv6?

    gateway = to_range.first.to_s.split('.')
    broadcast = to_range.last.to_s.split('.')
    first, last = gateway.zip(broadcast)
      .map{|a,b| [a, b] == %w(0 255) ? %w(* *) : [a, b]}
      .transpose
      .map{|quads| quads.join('.')}

    first == last ? first : "#{first}-#{last}"
  end

  # Render as a range string
  def to_vendor_range_format
    "#{to_range.first.to_s}-#{to_range.last.to_s}"
  end
end
