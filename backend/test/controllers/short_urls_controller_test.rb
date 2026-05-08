require 'test_helper'

class ShortUrlsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123'
    )

    @token = JwtService.encode(user_id: @user.id)
  end

  test 'rejects create without authentication' do
    post '/shorten', params: { long_url: 'https://example.com' }

    assert_response :unauthorized

    body = JSON.parse(response.body)
    assert_equal 'Unauthorized', body['error']
  end

  test 'should create short url successfully' do
    post '/shorten', params: { long_url: 'https://www.example.com' }, headers: { 'Authorization' => "Bearer #{@token}" }

    assert_response :success
    body = JSON.parse(response.body)

    assert_not_nil body['short_code']
  end

  test 'should not create short url without long url' do
    post '/shorten', params: {}, headers: { 'Authorization' => "Bearer #{@token}" }

    assert_response :bad_request
    body = JSON.parse(response.body)

    assert_equal 'Long URL must be provided', body['error']
  end

  test 'should return same short code for same long url' do
    post '/shorten', params: { long_url: 'https://www.example.com' }, headers: { 'Authorization' => "Bearer #{@token}" }
    first = JSON.parse(response.body)['short_code']

    post '/shorten', params: { long_url: 'https://www.example.com' }, headers: { 'Authorization' => "Bearer #{@token}" }
    second = JSON.parse(response.body)['short_code']

    assert_equal first, second
  end

  test 'should redirect to original url' do
    short_url = short_urls(:one)

    get "/#{short_url.short_code}"

    assert_response :redirect
    assert_equal short_url.long_url, response.location
  end

  test 'should return not found for invalid short_code' do
    get '/invalidcode'

    assert_response :not_found
    body = JSON.parse(response.body)

    assert_equal 'Not found', body['error']
  end
end
