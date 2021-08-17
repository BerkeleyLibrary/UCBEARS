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

  class_attribute :visitor_ips, default: ['2001:400:613:: - 2001:400:613:FFFF:FFFF:FFFF:FFFF:FFFF']

  def initialize(range, organization)
    @organization = organization
    super(range)
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
      Nokogiri::HTML(raw_html).css('table:first').css('tr:nth-child(n+3)').css('td:first').map do |node|
        next unless node.search('sup').empty?

        new(node.text, :ucb) unless IPAddr.new(node.text).private?
      end
    end

    def parse_campus_ipv6_ranges(raw_html)
      generated = []
      Nokogiri::HTML(raw_html).css('table:first').css('tr:nth-child(n+3)').css('td:first').map do |node|
        unless node.search('sup').empty?
          generated.concat(generate_from_network(node.text.chop)) if node.search('sup').text == '2'
        end
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

    def generate_from_network(current_ip_range)
      ip = IPAddr.new(current_ip_range)
      generated_networks = []
      omitted_ips.each do |omit|
        next unless ip.include? omit[0]

        generated_networks.concat(network_bounds(ip, omit))
      end
      generated_networks
    end

    def network_bounds(ip, omit)
      range = ip.to_range
      first_ip = range.first
      last_ip = range.last
      [first_ip.to_s + ' - ' + omit[1], omit[2] + ' - ' + last_ip.to_s]
    end

    def parse_lbl_addresses(raw_html)
      Nokogiri::HTML(raw_html).css('td:nth-child(n+2)').map do |node|
        range = node.text.gsub(/\s+/, '').split(/\s*-\s*/)
        new(convert_to_cidrs(range), :lbl) unless IPAddr.new(range[1]).private? || IPAddress.valid_ipv6?(range[1])
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

end
