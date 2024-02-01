module CampusNetworkHelper

  def get_formatted_ranges(network_array)
    return { ranged: [], starred: [] } if network_array.select(&:ipv4?).empty?

    merged = connect_contiguous_ranges(network_array.select(&:ipv4?)).compact
    # add guard clause
    { ranged: to_ranged_format(merged),
      starred: to_starred_format(merged) }
  end

  # TODO: refactor this method to a library
  def connect_contiguous_ranges(network_array) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    merged = []
    network_array.sort.each do |network|
      range = network.to_range
      if !merged.empty? && merged.last[:succ] == range.begin.to_s
        merged.last[:end] = range.end.to_s
        merged.last[:succ] = range.end.succ.to_s
      else
        merged << { start: range.begin.to_s,
                    end: range.end.to_s,
                    succ: range.end.succ.to_s }
      end
    end
    merged
  end

  def to_ranged_format(range_array)
    range_array.map do |r|
      "#{r[:start]}-#{r[:end]}"
    end
  end

  def to_starred_format(range_array)
    range_array.map do |r|
      gateway = r[:start].split('.')
      broadcast = r[:end].split('.')
      first, last = gateway.zip(broadcast)
        .map { |a, b| [a, b] == %w[0 255] ? %w[* *] : [a, b] }
        .transpose
        .map { |quads| quads.join('.') }

      first == last ? first : "#{first}-#{last}"
    end
  end
end
