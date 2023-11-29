require 'nokogiri'
require 'netaddr'
require 'ipaddress'
require 'open-uri'

class CampusNetwork < IPAddr
  # @return [Symbol] Organization that owns the network (:ucb, :lbl)
  attr_reader :organization

  # @return [String] Address of the nettools page listing all campus networks
  class_attribute :lbl_url, default: 'https://whois.arin.net/rest/org/LBNL/nets'

  # @return [String] Address of the nettools page listing all campus networks
  class_attribute :ucb_url, default: 'https://berkeley.service-now.com/kb_view.do?sysparm_article=KB0011960'

  # @return [[String]] Address of ip's to be ommited and the ranges bounds used
  class_attribute :omitted_ips, default: [
    ['2607:f140:6000::/48', '2607:f140:5999:ffff:ffff:ffff:ffff:ffff', '2607:f140:6001:0000:0000:0000:0000:0000']
  ]

  class_attribute :blocked_sups, default: [1,2]

  class_attribute :visitor_ips, default: ['2001:400:613:: - 2001:400:613:FFFF:FFFF:FFFF:FFFF:FFFF']

  def initialize(raw_addr, format = Socket::AF_INET, organization:)
    @raw_addr = raw_addr
    @organization = organization
    super(raw_addr, format)
  end

  class << self
    def all(organization: nil)
      (ucb_networks + lbl_networks).select do |network|
        organization.blank? || network.organization == organization.to_sym if network
      end
    end

    def ipv6_ranges(org)
      ipv6 = []
      ipv6.concat(parse_lbl_ipv6_ranges(URI(lbl_url).read('Accept' => 'text/html'))) unless org == 'ucb'
      ipv6.concat(parse_campus_ipv6_ranges(URI(ucb_url).read('Accept' => 'text/html'))) unless org == 'lbl'

      ipv6
    end

    private

    def lbl_networks
      raw_html = URI(lbl_url).read('Accept' => 'text/html')
      parse_lbl_addresses(raw_html)
    end

    def ucb_networks
      raw_html = URI(ucb_url).read('Accept' => 'text/html')
      parse_campus_addresses(raw_html)
    end

    def parse_campus_addresses(raw_html)
      ipv4_ranges = Nokogiri::HTML(raw_html).css('table:first').css('tr:nth-child(n+3)').css('td:first').map do |node|
        next unless node.search('sup').empty?
        node.text unless IPAddr.new(node.text).private?
      end
      filtered = remove_ipv4_omits(ipv4_ranges.compact, parse_campus_ipv4_omits(raw_html)).compact
      
    end

    def remove_ipv4_omits(full_ranges, omits)
      # permitted_ranges = []
      # full_ranges.map do |node|
      #   permitted_ranges.concat(generate_from_network(node.text, omits)
      # end
      # permitted_ranges
      full_ranges
    end

    def parse_campus_ipv4_omits(raw_html)
      restricted_ranges = []
      Nokogiri::HTML(raw_html).xpath('//h2[contains(text(),"Wireless")]/following-sibling::table[1]').first.css('td:first').map do |node|
        next unless !node.search('sup').empty? && (node.search('sup').text == '1')
        restricted_ranges.push(IPAddr.new(node.text.chop)) if IPAddr.new(node.text.chop).ipv4?
      end
      restricted_ranges.compact
    end

    def parse_campus_ipv6_ranges(raw_html)
      generated = []
      Nokogiri::HTML(raw_html).css('table:first').css('tr:nth-child(n+3)').css('td:first').map do |node|
        generated.concat(generate_from_network(node.text.chop)) if !node.search('sup').empty? && (node.search('sup').text == '2')
      end
      generated
    end

    def parse_lbl_ipv6_ranges(raw_html)
      lbl_ranges = []
      Nokogiri::HTML(raw_html).css('td:nth-child(n+2)').map do |node|
        range = node.text.gsub(/\s+/, '').split(/\s*-\s*/)
        lbl_ranges.push(node.text) unless IPAddress.valid_ipv4?(range[1]) || visitor_ips.include?(node.text)
      end
      lbl_ranges
    end

    def generate_from_network(current_ip_range, omit_array = Array.new(omitted_ips[0]))
      ip = IPAddr.new(current_ip_range)
      generated_networks = []
      omit_array.each do |omit|
        next unless ip.include? omit

        generated_networks.concat(network_bounds(ip, omit))
      end
      generated_networks
    end

    def network_bounds(ip, omit)
      ip_range = ip.to_range
      omit_range = omit.to_range
      first_ip = ip_range.first
      last_ip = ip_range.last
      ["#{first_ip} - #{omit_range.first}", "#{omit_range.last} - #{last_ip}"]
    end

    def parse_lbl_addresses(raw_html)
      Nokogiri::HTML(raw_html).css('td:nth-child(n+2)').map do |node|
        range = node.text.gsub(/\s+/, '').split(/\s*-\s*/)
        new(convert_to_cidrs(range), organization: :lbl) unless IPAddr.new(range[1]).private? || IPAddress.valid_ipv6?(range[1])
      end
    end

    def convert_to_cidrs(range)
      # TODO: NetAddr performance: find something faster
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

  def to_range
    raw_ipaddr = IPAddr.new(@raw_addr, family)
    @range_val ||= raw_ipaddr.to_range
  end

end
