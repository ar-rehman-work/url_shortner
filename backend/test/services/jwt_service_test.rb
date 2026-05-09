require 'test_helper'

class JwtServiceTest < ActiveSupport::TestCase
  def setup
    @payload = { user_id: 1 }
    @token = JwtService.encode(@payload)
  end

  test 'encodes payload into a token' do
    assert_not_nil @token
    assert_kind_of String, @token
  end

  test 'decodes valid token' do
    decoded = JwtService.decode(@token)

    assert_not_nil decoded
    assert_equal 1, decoded['user_id']
  end

  test 'returns nil for invalid token' do
    decoded = JwtService.decode('invalid.token.string')

    assert_nil decoded
  end

  test 'returns nil for tampered token' do
    parts = @token.split('.')
    tampered_token = "#{parts[0]}.tampered.#{parts[2]}"

    decoded = JwtService.decode(tampered_token)

    assert_nil decoded
  end

  test 'returns nil for empty token' do
    decoded = JwtService.decode(nil)

    assert_nil decoded
  end
end
