module ValidProxyPatron

  class << self

    # rubocop:disable Metrics/AbcSize
    def valid?(patron)
      patron['status']['value'] == 'ACTIVE' &&
      patron['user_block'].empty? &&
      fees_less_than?(patron['fees']['value'].to_f, 50) &&
      valid_group?(patron['user_group']['value'])
    end
    # rubocop:enable Metrics/AbcSize

    def fees_less_than?(fee, max)
      fee < max
    end

    # put the groups in a config somewhere.
    def valid_group?(group)
      libproxy_groups.include? group
    end

    private

    def libproxy_groups
      Rails.application.config.libproxy_groups
    end

  end
end
