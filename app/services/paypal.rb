# TODO: - finish this service module
module PayPal
  TEST_ENDPOINT = 'https://pilot-payflowpro.paypal.com'.freeze
  LIVE_ENDPOINT = 'https://payflowpro.paypal.com'.freeze

  class PayFlow
    def self.test
      puts 'PayPal.PayFlow says hello!'
    end
  end
end
