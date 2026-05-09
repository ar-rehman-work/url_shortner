require 'test_helper'

class ShortUrlsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123'
    )

    @token = JwtService.encode(user_id: @user.id)
    @headers = { 'Authorization' => "Bearer #{@token}" }
  end

  test 'rejects create without authentication' do
    post '/shorten', params: { long_url: 'https://example.com' }

    assert_response :unauthorized

    body = JSON.parse(response.body)
    assert_equal 'Unauthorized', body['error']
  end

  test 'creates short url successfully when authenticated' do
    post '/shorten', params: { long_url: 'https://example.com' }, headers: @headers

    assert_response :success

    body = JSON.parse(response.body)
    assert_not_nil body['short_code']
  end

  test 'rejects create without long url' do
    post '/shorten', params: { }, headers: @headers

    assert_response :bad_request

    body = JSON.parse(response.body)
    assert_equal 'Long url must be provided', body['error']
  end

  test 'rejects create with invalid long url' do
    post '/shorten', params: { long_url: 'invalid_url' }, headers: @headers

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)
    assert_includes body['errors'], 'Long url must be a valid URL'
  end

  test 'returns same short code for same long url for same user' do
    post '/shorten', params: { long_url: 'https://example.com' }, headers: @headers

    first = JSON.parse(response.body)['short_code']

    post '/shorten', params: { long_url: 'https://example.com' }, headers: @headers

    second = JSON.parse(response.body)['short_code']

    assert_equal first, second
  end

  test 'different users can have same long url but different records' do
    user2 = User.create!(
      name: 'User Two',
      email: 'user2@example.com',
      password: 'password123'
    )

    token2 = JwtService.encode(user_id: user2.id)
    headers2 = { 'Authorization' => "Bearer #{token2}" }

    post '/shorten', params: { long_url: 'https://example.com' }, headers: @headers

    first_user_code = JSON.parse(response.body)['short_code']

    post '/shorten', params: { long_url: 'https://example.com' }, headers: headers2

    second_user_code = JSON.parse(response.body)['short_code']

    assert_not_equal first_user_code, second_user_code
  end

  test 'redirects to original url' do
    short_url = ShortUrl.create!(user_id: @user.id, long_url: 'https://example.com')

    get "/#{short_url.short_code}"

    assert_response :redirect
    assert_equal short_url.long_url, response.location
  end

  test 'returns not found for invalid short code' do
    get '/invalidcode'

    assert_response :not_found

    body = JSON.parse(response.body)
    assert_equal 'Not found', body['error']
  end
end
