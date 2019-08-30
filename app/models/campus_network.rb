require 'nokogiri'
require 'open-uri'

class CampusNetwork < IPAddr
  # @return [Symbol] Organization that owns the network (:ucb, :lbl)
  attr_accessor :organization

  # @return [Array<String>] list of known LBL networks (manually curated...)
  class_attribute :lbl_subnets, default: %w[
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
  ]

  # @return [String] Address of the nettools page listing all campus networks
  class_attribute :source_url, default: 'https://nettools.net.berkeley.edu/pubtools/info/campusnetworks.html'

  class << self
    # @param [String] organization Only return networks belonging to this org
    # @return [Array<CampusNetwork>]
    def all(organization: nil)
      (ucb_networks + lbl_networks).select do |network|
        organization.blank? || network.organization == organization.to_sym
      end
    end

    private

    def lbl_networks
      lbl_subnets.map do |str|
        network = new(str)
        network.organization = :lbl
        network
      end
    end

    def ucb_networks
      raw_html = URI.parse(source_url).read
      parse_campus_addresses(raw_html)
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
    # @return [Array<CampusNetwork>]
    def parse_campus_addresses(raw_html)
      Nokogiri::HTML(raw_html)
        .css('#ucbito_main_container table:first') # get the first table
        .css('tr:nth-child(n+3)') # skip the two header rows
        .css('td:first') # get the first column
        .map do |node|
          node.css('strong').remove
          network = new(node.text)
          network.organization = :ucb
          network
        end
    end
  end

  # Render as a star-formatted string
  # @return [String]
  # rubocop:disable Metrics/AbcSize
  def to_vendor_star_format
    raise "Star format doesn't work for IPv6" if ipv6?

    gateway = to_range.first.to_s.split('.')
    broadcast = to_range.last.to_s.split('.')
    first, last = gateway.zip(broadcast)
      .map { |a, b| [a, b] == %w[0 255] ? %w[* *] : [a, b] }
      .transpose
      .map { |quads| quads.join('.') }

    first == last ? first : "#{first}-#{last}"
  end
  # rubocop:enable Metrics/AbcSize

  # Render as a range string
  # @return [String]
  def to_vendor_range_format
    "#{to_range.first}-#{to_range.last}"
  end
end
