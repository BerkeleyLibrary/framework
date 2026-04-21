require 'jwt'
require 'net/http'
require 'json'

module AlmaJwtValidator
  JWKS_URL = 'https://api-na.hosted.exlibrisgroup.com/auth/01UCS_BER/jwks.json'.freeze
  EXPECTED_ISS = 'Prima'.freeze

  module_function

  def jwk_set
    Rails.cache.fetch('jwks_set', expires_in: 4.hour) do
      jwks_raw = Net::HTTP.get(URI(JWKS_URL))
      jwks_keys = JSON.parse(jwks_raw)['keys']
      JWT::JWK::Set.new(jwks_keys)
    end
  end

  def decode_and_verify_jwt(token)
    options = {
      algorithm: 'ES256',
      verify_expiration: true,
      verify_aud: false,
      verify_iss: true,
      iss: EXPECTED_ISS,
      jwks: jwk_set
    }

    JWT.decode(token, nil, true, options)
  end
end
