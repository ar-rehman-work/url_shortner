require 'test_helper'

class ShortUrlsControllerTest < ActionDispatch::IntegrationTest
  def setup
    ShortUrl.const_set(:HOST, 'http://localhost:3000') unless ShortUrl.const_defined?(:HOST)

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
    post '/shorten',
         params: { long_url: 'https://example.com' },
         headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_not_nil body['short_url']
    assert_match(%r{\Ahttp://localhost:3000/s/[a-zA-Z0-9]+\z}, body['short_url'])
  end

  test 'rejects create without long url' do
    post '/shorten', params: {}, headers: @headers

    assert_response :bad_request

    body = JSON.parse(response.body)

    assert_equal 'Long url must be provided', body['error']
  end

  test 'rejects create with invalid long url' do
    post '/shorten',
         params: { long_url: 'invalid_url' },
         headers: @headers

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert body['errors'].any?
  end

  test 'returns same short url for same long url for same user' do
    post '/shorten', params: { long_url: 'https://example.com' }, headers: @headers
    first = JSON.parse(response.body)['short_url']

    post '/shorten', params: { long_url: 'https://example.com' }, headers: @headers
    second = JSON.parse(response.body)['short_url']

    assert_response :success

    assert_equal first, second
    assert_equal 1, @user.short_urls.count
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
    first_user_url = JSON.parse(response.body)['short_url']

    post '/shorten', params: { long_url: 'https://example.com' }, headers: headers2
    second_user_url = JSON.parse(response.body)['short_url']

    assert_response :success

    assert_not_equal first_user_url, second_user_url
  end

  test 'creates short url with custom alias' do
    post '/shorten',
         params: {
           long_url: 'https://example.com',
           custom_alias: 'myalias'
         },
         headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 'http://localhost:3000/myalias', body['short_url']
  end

  test 'rejects duplicate custom alias' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://google.com',
      custom_alias: 'takenalias'
    )

    post '/shorten',
         params: {
           long_url: 'https://example.com',
           custom_alias: 'takenalias'
         },
         headers: @headers

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert body['errors'].any?
  end

  test 'creates short url with expiration date' do
    expires_at = 2.days.from_now

    post '/shorten',
         params: {
           long_url: 'https://example.com',
           expires_at: expires_at
         },
         headers: @headers

    assert_response :success

    short_url = ShortUrl.last

    assert_not_nil short_url.expires_at
  end

  test 'redirects using short code route' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    short_url.reload

    get "/s/#{short_url.short_code}"

    assert_response :redirect
    assert_equal short_url.long_url, response.location
  end

  test 'redirects using custom alias route' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com',
      custom_alias: 'github'
    )

    get '/github'

    assert_response :redirect
    assert_equal short_url.long_url, response.location
  end

  test 'returns gone for expired short url' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    short_url.reload
    short_url.update_column(:expires_at, 1.day.ago)

    get "/s/#{short_url.short_code}"

    assert_response :gone

    body = JSON.parse(response.body)

    assert_equal 'URL has expired', body['error']
  end

  test 'returns not found for invalid short code' do
    get '/s/invalidcode'

    assert_response :not_found

    body = JSON.parse(response.body)

    assert_equal 'Not found', body['error']
  end

  test 'returns paginated short urls list' do
    15.times do |i|
      ShortUrl.create!(
        user_id: @user.id,
        long_url: "https://example#{i}.com"
      )
    end

    get '/',
        params: { limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 10, body['data'].length
    assert_not_nil body['pagination']
    assert body['data'][0].key?('short_url')
    assert body['data'][0].key?('custom')
  end

  test 'filters short urls by search query' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://google.com',
      custom_alias: 'google'
    )

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://github.com',
      custom_alias: 'github'
    )

    get '/',
        params: { q: 'github', limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body['data'].length
    assert_equal 'https://github.com', body['data'][0]['long_url']
    assert_equal true, body['data'][0]['custom']
    assert_equal 'http://localhost:3000/github', body['data'][0]['short_url']
  end

  test 'filters expired urls when expired=true' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://expired.com'
    )

    short_url.update_column(:expires_at, 1.day.ago)

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://active.com',
      expires_at: 1.day.from_now
    )

    get '/', params: { expired: true, limit: 10 }, headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body['data'].length
    assert_equal 'https://expired.com', body['data'][0]['long_url']
  end

  test 'filters active urls when expired=false' do
    ShortUrl.create!(user_id: @user.id, long_url: 'https://expired.com').tap do |u|
      u.update_column(:expires_at, 1.day.ago)
    end

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://active.com',
      expires_at: 1.day.from_now
    )

    get '/', params: { expired: false, limit: 10 }, headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body['data'].length
    assert_equal 'https://active.com', body['data'][0]['long_url']
  end

  test 'returns all urls when expired param is missing' do
    ShortUrl.create!(user_id: @user.id, long_url: 'https://expired.com').tap do |u|
      u.update_column(:expires_at, 1.day.ago)
    end

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://active.com',
      expires_at: 1.day.from_now
    )

    get '/', params: { limit: 10 }, headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 2, body['data'].length
  end

  test 'returns all urls when expired param is invalid' do
    ShortUrl.create!(user_id: @user.id, long_url: 'https://expired.com').tap do |u|
      u.update_column(:expires_at, 1.day.ago)
    end

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://active.com',
      expires_at: 1.day.from_now
    )

    get '/', params: { expired: 'invalid', limit: 10 }, headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 2, body['data'].length
  end
end
