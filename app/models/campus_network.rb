require 'nokogiri'
require 'netaddr'
require 'ipaddress'

class CampusNetwork < IPAddr
  # @return [Symbol] Organization that owns the network (:ucb, :lbl)
  attr_accessor :organization

  # @return [String] Address of the nettools page listing all campus networks
  class_attribute :lbl_url, default: 'https://whois.arin.net/rest/org/LBNL/nets'

  # @return [String] Address of the nettools page listing all campus networks
  class_attribute :source_url, default: 'https://berkeley.service-now.com/kb_view.do?sysparm_article=KB0011960'

  class << self
    def all(organization: nil)
      (ucb_networks + lbl_networks).select do |network|
        organization.blank? || network.organization == organization.to_sym if network
      end
    end

    private

    def lbl_networks
      raw_html = URI.parse(lbl_url).read
      parse_lbl_addresses(raw_html)
    end

    def ucb_networks
      raw_html = URI.parse(source_url).read
      parse_campus_addresses(raw_html)
    end

    def parse_campus_addresses(raw_html)
      Nokogiri::HTML(raw_html)
        .css('table:first')
        .css('tr:nth-child(n+3)')
        .css('td:first')
        .map do |node|
          node.css('strong').remove
          network = new(node.text)
          network.organization = :ucb
          network
        end
    end

    def parse_lbl_addresses(raw_html)
      Nokogiri::HTML(raw_html)
        .css('td:nth-child(n+2)')
        .map do |node|
          range = node.text.gsub(/\s+/, '').split(/\s*-\s*/)
          next unless IPAddress.valid_ipv4? range[1]

          network = new(convert_to_cirds(range))
          network.organization = :lbl
          network
        end
    end

    def convert_to_cirds(range)
      ip_net_range = NetAddr.range(range[0], range[1], Inclusive: true, Objectify: true)
      cidrs = NetAddr.merge(ip_net_range, Objectify: true)
      cidrs[0].to_s
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
