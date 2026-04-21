require 'rails_helper'
require 'jwt'
require 'json'
require 'openssl'

describe AlmaJwtValidator do
  let(:alma_institution_code) { '01UCS_BER' }
  let(:jwks_url) { "https://api-na.hosted.exlibrisgroup.com/auth/#{alma_institution_code}/jwks.json" }
  let(:expected_iss) { 'Prima' }

  # Generate an EC key pair for testing
  let(:ec_key) { OpenSSL::PKey::EC.generate('prime256v1') }
  let(:kid) { 'test-key-id' }
  let(:test_payload) { { 'userName' => '10335026', 'iss' => expected_iss } }

  # Helper to create JWK hash from EC key using JWT::JWK
  def create_jwk_hash(key, kid)
    jwk = JWT::JWK.new(key, kid: kid)
    jwk.export
  end

  # Helper to generate a valid JWT
  def generate_jwt(payload, key, kid, algorithm = 'ES256')
    header = { 'kid' => kid, 'alg' => algorithm }
    JWT.encode(payload, key, algorithm, header)
  end

  before do
    jwk = create_jwk_hash(ec_key, kid)

    stub_request(:get, jwks_url)
      .to_return(
        status: 200,
        body: { 'keys' => [jwk] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '.decode_and_verify_jwt' do
    context 'with a valid JWT' do
      it 'returns the decoded payload' do
        token = generate_jwt(test_payload, ec_key, kid)
        result = AlmaJwtValidator.decode_and_verify_jwt(token)

        expect(result).to be_an(Array)
        expect(result[0]['userName']).to eq('10335026')
        expect(result[1]['kid']).to eq(kid)
      end
    end

    context 'with an invalid signature' do
      it 'raises JWT::DecodeError' do
        # Generate a token with a different key
        different_key = OpenSSL::PKey::EC.generate('prime256v1')
        token = generate_jwt(test_payload, different_key, kid)

        expect do
          AlmaJwtValidator.decode_and_verify_jwt(token)
        end.to raise_error(JWT::DecodeError)
      end
    end

    context 'with an unknown key id' do
      it 'raises JWT::DecodeError' do
        token = generate_jwt(test_payload, ec_key, 'unknown-kid')

        expect do
          AlmaJwtValidator.decode_and_verify_jwt(token)
        end.to raise_error(JWT::DecodeError)
      end
    end

    context 'with a malformed JWT' do
      it 'raises JWT::DecodeError' do
        expect do
          AlmaJwtValidator.decode_and_verify_jwt('not.a.jwt')
        end.to raise_error(JWT::DecodeError)
      end
    end

    context 'when JWKS endpoint is unreachable' do
      it 'raises an error' do
        stub_request(:get, jwks_url).to_return(status: 500)
        token = generate_jwt(test_payload, ec_key, kid)

        expect do
          AlmaJwtValidator.decode_and_verify_jwt(token)
        end.to raise_error(StandardError)
      end
    end
  end
end
