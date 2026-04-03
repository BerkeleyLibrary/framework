require 'jwt'
require 'net/http'
require 'json'

module AlmaJwtValidator
  JWKS_URL = 'https://api-na.hosted.exlibrisgroup.com/auth/01UCS_BER/jwks.json'.freeze
  EXPECTED_ISS = 'https://api-na.hosted.exlibrisgroup.com/auth/01UCS_BER'.freeze

  module_function

  def jwk_set
    Rails.cache.fetch('jwks_set', expires_in: 4.hour) do
      jwks_raw = Net::HTTP.get(URI(JWKS_URL))
      jwks_keys = JSON.parse(jwks_raw)['keys']
      JWT::JWK::Set.new(jwks_keys)
    end
  end

  # rubocop:disable Metrics/MethodLength
  def decode_and_verify_jwt(token)
    # Decode header to get the 'kid'
    header = JWT.decode(token, nil, false).last
    kid = header['kid']

    # Find the key from the JWK set
    jwk = jwk_set.keys.find { |key| key.kid == kid }
    raise JWT::VerificationError, 'Key not found in JWKS' unless jwk

    public_key = jwk.public_key

    options = {
      algorithm: 'RS256',
      verify_expiration: true,
      verify_aud: false,
      verify_iss: true,
      iss: EXPECTED_ISS
    }

    # Returns [payload, header] array if valid
    JWT.decode(token, public_key, true, options)
  rescue JWT::ExpiredSignature
    raise JWT::VerificationError, 'Token has expired'
  rescue JWT::InvalidIssuerError
    raise JWT::VerificationError, 'Token issuer mismatch'
  rescue JWT::DecodeError => e
    raise JWT::VerificationError, "Invalid JWT: #{e.message}"
  end
  # rubocop:enable Metrics/MethodLength
end
