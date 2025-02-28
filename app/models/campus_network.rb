require 'nokogiri'
require 'netaddr'
require 'ipaddress'
require 'open-uri'

class CampusNetwork < IPAddr # rubocop:disable Metrics/ClassLength
  # @return [Symbol] Organization that owns the network (:ucb, :lbl)
  attr_reader :organization

  # @return [String] Address of the nettools page listing all campus networks
  class_attribute :lbl_url, default: 'https://whois.arin.net/rest/org/LBNL/nets'
  class_attribute :lblz_url, default: 'https://whois.arin.net/rest/org/LBNL-Z/nets'

  # @return [String] Address of the nettools page listing all campus networks
  class_attribute :ucb_url, default: 'https://berkeley.service-now.com/kb_view.do?sysparm_article=KB0011960'

  # @return [[String]] Address of campus ip's to be ommited and the ranges bounds used
  # deprecated
  class_attribute :omitted_ips, default: [
    ['2607:f140:6000::/48', '2607:f140:5999:ffff:ffff:ffff:ffff:ffff', '2607:f140:6001:0000:0000:0000:0000:0000']
  ]

  # @return [[String]] Network cidrs from campus that have restricted access to library resources
  # Specifically, these are the hardcoded networks for 'Authenticated IPv6 Public Network' and
  # bsecure vpn 'Full, Library, and Auto Tunnel Networks'
  # TODO: refactor to use a config file or to better parse acceptable ipv6 networks from the ucb_url
  class_attribute :campus_ipv6_cidrs, default: [
    '2607:f140:400::/48', '2607:f140:800:1::/64'
  ]

  class_attribute :blocked_sups, default: %w[1 2]

  class_attribute :visitor_ips, default: ['2001:400:613:: - 2001:400:613:FFFF:FFFF:FFFF:FFFF:FFFF']

  def initialize(raw_addr, format = Socket::AF_INET, organization) # rubocop:disable Style/OptionalArguments
    @raw_addr = raw_addr
    @organization = organization
    super(raw_addr, format)
  end

  class << self
    def all(organization: nil)
      (ucb_networks + lbl_networks + lblz_networks).select do |network|
        result = organization.blank? || network.organization == organization.to_sym if network
        result
      end
    end

    def ipv6_ranges(org) # rubocop:disable Metrics/AbcSize
      ipv6 = []
      ipv6.concat(parse_lbl_ipv6_ranges(URI(lbl_url).read('Accept' => 'text/html'))) unless org == 'ucb'
      ipv6.concat(parse_lbl_ipv6_ranges(URI(lblz_url).read('Accept' => 'text/html'))) unless org == 'ucb'

      unless org == 'lbl'
        ipv6.concat(campus_ipv6_cidrs.map do |cidr|
          network = IPAddr.new(cidr)
          "#{network.to_range.first} - #{network.to_range.last}"
        end)
      end

      ipv6
    end

    private

    def lbl_networks
      raw_html = URI(lbl_url).read('Accept' => 'text/html')
      parse_lbl_addresses(raw_html)
    end

    def lblz_networks
      raw_html = URI(lblz_url).read('Accept' => 'text/html')
      parse_lbl_addresses(raw_html)
    end

    def ucb_networks
      raw_html = URI(ucb_url).read('Accept' => 'text/html')
      good_networks = parse_and_collect_good_campus_cidrs(raw_html).compact
      unique_ranges = remove_covered_ucb_networks(good_networks)
      campus_ipv4_omits = parse_campus_ipv4_omits(raw_html)
      remove_ipv4_omits(unique_ranges.concat, campus_ipv4_omits.concat)
    end

    # rubocop:disable Lint/UselessAssignment

    # Parses the raw html, grabs all the cidr networks from the first table
    #  that don't have restricted super script notations or are private networks,
    #  and finally returns an array of CampusNetwork objects
    #
    # @param raw_html [String]
    # @return [[CampusNetwork]]
    def parse_and_collect_good_campus_cidrs(raw_html) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      good_nodes = Nokogiri::HTML(raw_html).css('table:first').css('tr:nth-child(n+3)').css('td:first').map do |node|
        next unless node.search('sup').empty? || blocked_sups.exclude?(node.search('sup').text)

        node.search('sup').empty? ? node.text : node.text.chop
      end.compact
      good_nodes.map do |cidr_string|
        next if cidr_string.nil?

        addr = IPAddr.new(cidr_string)
        new(cidr_string, organization = :ucb) unless addr.ipv6? || addr.private?
      end.compact.reject { |item| !item.is_a?(self) } # rubocop:disable Style/MultilineBlockChain
    end

    # Sorts networks by size, then removes any networks that are covered by a larger network
    #
    # @param networks_arr [[CampusNetwork]]
    # @return [[CampusNetwork]]
    def remove_covered_ucb_networks(networks_arr)
      sorted = networks_arr.sort_by { |addr| addr.to_range.size }
      sorted.reject.with_index do |network, index|
        sorted[(index + 1)..].any? { |other_network| other_network.to_range.cover?(network.to_range) }
      end
    end

    # splits any ipv4 network ranges that cover omitted networks
    #
    # @param full_ranges [[CampusNetwork]]
    # @param omits [[IPAddr]]
    # @return [[CampusNetwork]]
    def remove_ipv4_omits(full_ranges, omits) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      permitted_ranges = []
      full_ranges.each do |original_range|
        overlaps = omits.select { |omit| original_range.to_range.cover?(omit.to_range) }

        if overlaps.empty? # TODO: refactor to overlaps.empty? ? orginal_range : call function for else block
          permitted_ranges << original_range
        else
          overlaps.each do |omit|
            remainders = NetAddr::CIDR.create(to_cidr_s(original_range)).remainder(to_cidr_s(omit))
            remainders.each do |remainder|
              permitted_ranges << new(remainder, organization = :ucb)
            end
          end
        end
      end
      permitted_ranges
    end

    # Parses the raw html, returns all the cidr networks from the second table that
    # have restricted super script notations & are ipv4 & are not private networks
    #
    # @param raw_html [String]
    # @return [[IPAddr]]
    def parse_campus_ipv4_omits(raw_html) # rubocop:disable Metrics/AbcSize
      restricted_ranges = []
      Nokogiri::HTML(raw_html).xpath('//h2[contains(text(),"Wireless")]/following-sibling::table[1]').first.css('td:first').map do |node|
        next unless !node.search('sup').empty? && blocked_sups.include?(node.search('sup').text)

        suspect_range = IPAddr.new(node.text.chop)
        restricted_ranges.push(suspect_range) if suspect_range.ipv4? && !suspect_range.private?
      end
      restricted_ranges.compact
    end

    # debrecated due to complexity involved in parsing the ucb_url
    def parse_campus_ipv6_ranges(raw_html)
      generated = []
      Nokogiri::HTML(raw_html).css('table:first').css('tr:nth-child(n+3)').css('td:first').map do |node|
        generated.concat(generate_from_network(node.text.chop)) if !node.search('sup').empty? && (node.search('sup').text == '2')
      end
      generated
    end

    def parse_lbl_ipv6_ranges(raw_html)
      lbl_ranges = []
      Nokogiri::HTML(raw_html).css('td:nth-child(2)').map do |node|
        range = node.text.gsub(/\s+/, '').split(/\s*-\s*/)
        lbl_ranges.push(node.text) unless IPAddress.valid_ipv4?(range[1]) || visitor_ips.include?(node.text)
      end
      lbl_ranges
    end

    # used to generate ipv6 networks
    # deprecated due to complexity involved in parsing the ucb_url
    def generate_from_network(current_ip_range)
      ip = IPAddr.new(current_ip_range)
      generated_networks = []
      omitted_ips.each do |omit|
        next unless ip.include? omit[0]

        generated_networks.concat(network_bounds(ip, omit))
      end
      generated_networks
    end

    # used to generate ipv6 range strings
    # deprecated due to complexity involved in parsing the ucb_url
    def network_bounds(ip, omit)
      range = ip.to_range
      first_ip = range.first
      last_ip = range.last
      ["#{first_ip} - #{omit[1]}", "#{omit[2]} - #{last_ip}"]
    end

    def parse_lbl_addresses(raw_html)
      Nokogiri::HTML(raw_html).css('td:nth-child(2)').map do |node|
        range = node.text.gsub(/\s+/, '').split(/\s*-\s*/)
        new(convert_to_cidrs(range), organization = :lbl) unless IPAddr.new(range[1]).private? || IPAddress.valid_ipv6?(range[1])
      end
    end

    # rubocop:enable Lint/UselessAssignment

    def convert_to_cidrs(range)
      # TODO: NetAddr performance: find something faster
      ip_net_range = NetAddr.range(range[0], range[1], Inclusive: true, Objectify: true)
      cidrs = NetAddr.merge(ip_net_range, Objectify: true)
      cidrs[0].to_s
    end

    # IPAddr object to string with prefix
    # @param ip [IPAddr]
    # @return [String]
    def to_cidr_s(ip)
      "#{ip}/#{ip.prefix}"
    end

    def previous_ip(ip_address)
      ip = IPAddr.new(ip_address).to_i
      previous_ip = IPAddr.new(ip - 1, Socket::AF_INET)
      previous_ip.to_s
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
