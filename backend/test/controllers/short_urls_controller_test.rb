
require 'test_helper'

class ShortUrlsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def setup
    ShortUrl.const_set(:HOST, 'http://localhost:3000') unless ShortUrl.const_defined?(:HOST)

    Rails.cache.clear
    REDIS.clear
    clear_enqueued_jobs
    clear_performed_jobs

    @user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123'
    )

    @token = JwtService.encode(user_id: @user.id)
    @headers = { 'Authorization' => "Bearer #{@token}" }
  end

  # CREATE

  test 'rejects create without authentication' do
    post '/api/v1/shorten', params: { long_url: 'https://example.com' }

    assert_response :unauthorized

    body = JSON.parse(response.body)

    assert_equal 'Unauthorized', body['error']
  end

  test 'creates short url successfully when authenticated' do
    post '/api/v1/shorten',
         params: { long_url: 'https://example.com' },
         headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_not_nil body['short_url']
    assert_match(%r{\Ahttp://localhost:3000/[a-zA-Z0-9]+\z}, body['short_url'])
  end

  test 'rejects create without long url' do
    post '/api/v1/shorten', params: {}, headers: @headers

    assert_response :bad_request

    body = JSON.parse(response.body)

    assert_equal 'Long url must be provided', body['error']
  end

  test 'rejects create with invalid long url' do
    post '/api/v1/shorten',
         params: { long_url: 'invalid_url' },
         headers: @headers

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert body['errors'].any?
  end

  test 'returns same short url for same long url for same user' do
    post '/api/v1/shorten', params: { long_url: 'https://example.com' }, headers: @headers
    first = JSON.parse(response.body)['short_url']

    post '/api/v1/shorten', params: { long_url: 'https://example.com' }, headers: @headers
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

    post '/api/v1/shorten',
         params: { long_url: 'https://example.com' },
         headers: @headers
    first_user_url = JSON.parse(response.body)['short_url']

    post '/api/v1/shorten',
         params: { long_url: 'https://example.com' },
         headers: headers2
    second_user_url = JSON.parse(response.body)['short_url']

    assert_response :success

    assert_not_equal first_user_url, second_user_url
  end

  test 'creates short url with custom alias' do
    post '/api/v1/shorten',
         params: {
           long_url: 'https://example.com',
           custom_alias: 'myalias'
         },
         headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 'http://localhost:3000/myalias', body['short_url']

    short_url = @user.short_urls.last

    assert_equal 'myalias', short_url.slug
    assert_equal true, short_url.custom
  end

  test 'creates short url with custom http url' do
    post '/api/v1/shorten',
         params: { long_url: 'http://example.com' },
         headers: @headers

    assert_response :success
  end

  test 'creates short url with custom localhost url' do
    post '/api/v1/shorten',
         params: { long_url: 'http://localhost:3000/google' },
         headers: @headers

    assert_response :success
  end

  test 'rejects duplicate custom alias' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://google.com',
      slug: 'takenalias'
    )

    post '/api/v1/shorten',
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

    post '/api/v1/shorten',
         params: {
           long_url: 'https://example.com',
           expires_at: expires_at
         },
         headers: @headers

    assert_response :success

    short_url = @user.short_urls.last

    assert_not_nil short_url.expires_at
  end

  # REDIRECT

  test 'redirects using generated slug' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    short_url.reload

    get "/#{short_url.slug}"

    assert_response :redirect
    assert_equal short_url.long_url, response.location
  end

  test 'redirects using custom alias' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com',
      slug: 'github'
    )

    get "/#{short_url.slug}"

    assert_response :redirect
    assert_equal short_url.long_url, response.location
  end

  test 'does not redirect inactive short url' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    short_url.update!(active: false)

    get "/#{short_url.slug}"

    assert_response :not_found
  end

  test 'caches redirect data for valid slug' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    get "/#{short_url.slug}"

    assert_response :redirect

    cached_data = Rails.cache.read("sc:#{short_url.slug}")

    assert_equal short_url.id, cached_data[:id]
    assert_equal short_url.long_url, cached_data[:long_url]
  end

  test 'caches not found response for invalid slug' do
    get '/invalidcode'

    assert_response :not_found

    assert_equal ShortUrlsController::NOT_FOUND,
                 Rails.cache.read('sc:invalidcode')
  end

  test 'clears redirect cache when short url becomes inactive' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    get "/#{short_url.slug}"

    assert_response :redirect
    assert Rails.cache.exist?("sc:#{short_url.slug}")

    short_url.update!(active: false)

    assert_not Rails.cache.exist?("sc:#{short_url.slug}")

    get "/#{short_url.slug}"

    assert_response :not_found
  end

  test 'clears old and new redirect cache keys when slug changes' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    old_slug = short_url.slug

    Rails.cache.write("sc:#{old_slug}", { id: short_url.id })
    short_url.update!(slug: 'new-alias')

    assert_not Rails.cache.exist?("sc:#{old_slug}")
    assert_not Rails.cache.exist?("sc:new-alias")
  end

  # CLICK TRACKING

  test 'tracks click data in redis when redirecting' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    short_url.reload

    get "/#{short_url.slug}"

    assert_response :redirect

    assert_includes REDIS.smembers('active_click_urls'), short_url.id.to_s
    assert_equal 1, REDIS.getdel("url:#{short_url.id}:click_count")
  end

  test 'tracks last click timestamp in redis when redirecting' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    short_url.reload

    get "/#{short_url.slug}"

    assert_response :redirect

    last_click_at = REDIS.getdel("url:#{short_url.id}:last_click_at")

    assert_not_nil last_click_at
    assert last_click_at.to_i <= Time.current.to_i
  end

  test 'enqueues track click job with correct arguments when redirecting' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    short_url.reload

    assert_enqueued_with(
      job: TrackClickJob,
      args: [
        short_url.id,
        '127.0.0.1',
        nil,
        nil
      ]
    ) do
      get "/#{short_url.slug}"
    end

    assert_response :redirect
  end

  test 'does not track redis click data for expired short url' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    short_url.reload
    short_url.update_column(:expires_at, 1.day.ago)

    get "/#{short_url.slug}"

    assert_response :gone

    assert_empty REDIS.smembers('active_click_urls')
    assert_nil REDIS.getdel("url:#{short_url.id}:click_count")
    assert_nil REDIS.getdel("url:#{short_url.id}:last_click_at")
  end

  test 'does not enqueue track click job for expired short url' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    short_url.reload
    short_url.update_column(:expires_at, 1.day.ago)

    assert_no_enqueued_jobs only: TrackClickJob do
      get "/#{short_url.slug}"
    end

    assert_response :gone
  end

  test 'does not track redis click data for invalid slug' do
    get '/invalidcode'

    assert_response :not_found

    assert_empty REDIS.smembers('active_click_urls')
  end

  test 'does not enqueue track click job for invalid slug' do
    assert_no_enqueued_jobs only: TrackClickJob do
      get '/invalidcode'
    end

    assert_response :not_found
  end

  test 'returns gone for expired short url' do
    short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    short_url.reload
    short_url.update_column(:expires_at, 1.day.ago)

    get "/#{short_url.slug}"

    assert_response :gone

    body = JSON.parse(response.body)

    assert_equal 'URL has expired', body['error']
  end

  test 'returns not found for invalid slug' do
    get '/invalidcode'

    assert_response :not_found

    body = JSON.parse(response.body)

    assert_equal 'Not found', body['error']
  end

  # INDEX / FILTERING / PAGINATION

  test 'returns paginated short urls list' do
    15.times do |i|
      ShortUrl.create!(
        user_id: @user.id,
        long_url: "https://example#{i}.com"
      )
    end

    get '/api/v1/',
        params: { limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 10, body['data'].length
    assert_not_nil body['pagination']
    assert body['data'][0].key?('short_url')
    assert body['data'][0].key?('custom')
  end

  test 'uses default pagination limit when limit is missing' do
    15.times do |i|
      ShortUrl.create!(
        user_id: @user.id,
        long_url: "https://example#{i}.com"
      )
    end

    get '/api/v1/', headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 10, body['data'].length
  end

  test 'respects Pagy maximum pagination limit' do
    105.times do |i|
      ShortUrl.create!(
        user_id: @user.id,
        long_url: "https://example#{i}.com"
      )
    end

    get '/api/v1/',
        params: { limit: 200 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 50, body['data'].length
  end

  test 'uses default pagination limit when limit is zero' do
    15.times do |i|
      ShortUrl.create!(
        user_id: @user.id,
        long_url: "https://example#{i}.com"
      )
    end

    get '/api/v1/',
        params: { limit: 0 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 10, body['data'].length
  end

  test 'filters short urls by search query' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://google.com',
      slug: 'google'
    )

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://github.com',
      slug: 'github'
    )

    get '/api/v1/',
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
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://expired.com'
    ).update_column(:expires_at, 1.day.ago)

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://active.com',
      expires_at: 1.day.from_now
    )

    get '/api/v1/',
        params: { expired: true, limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body['data'].length
    assert_equal 'https://expired.com', body['data'][0]['long_url']
  end

  test 'filters unexpired urls when expired=false' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://expired.com'
    ).update_column(:expires_at, 1.day.ago)

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://active.com',
      expires_at: 1.day.from_now
    )

    get '/api/v1/',
        params: { expired: false, limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body['data'].length
    assert_equal 'https://active.com', body['data'][0]['long_url']
  end

  test 'returns all urls when expired param is missing' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://expired.com'
    ).update_column(:expires_at, 1.day.ago)

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://active.com',
      expires_at: 1.day.from_now
    )

    get '/api/v1/', params: { limit: 10 }, headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 2, body['data'].length
  end

  test 'returns all urls when expired param is invalid' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://expired.com'
    ).update_column(:expires_at, 1.day.ago)

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://active.com',
      expires_at: 1.day.from_now
    )

    get '/api/v1/',
        params: { expired: 'invalid', limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 2, body['data'].length
  end

  test 'filters custom urls when custom=true' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://custom.com',
      slug: 'custom-url'
    )

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://generated.com'
    )

    get '/api/v1/',
        params: { custom: true, limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body['data'].length
    assert_equal 'https://custom.com', body['data'][0]['long_url']
    assert_equal true, body['data'][0]['custom']
  end

  test 'filters generated urls when custom=false' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://custom.com',
      slug: 'custom-url'
    )

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://generated.com'
    )

    get '/api/v1/',
        params: { custom: false, limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body['data'].length
    assert_equal 'https://generated.com', body['data'][0]['long_url']
    assert_equal false, body['data'][0]['custom']
  end

  test 'returns all urls when custom param is missing' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://custom.com',
      slug: 'custom-url'
    )

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://generated.com'
    )

    get '/api/v1/', params: { limit: 10 }, headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 2, body['data'].length
  end

  test 'returns all urls when custom param is invalid' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://custom.com',
      slug: 'custom-url'
    )

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://generated.com'
    )

    get '/api/v1/',
        params: { custom: 'invalid', limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 2, body['data'].length
  end

  test 'filters urls by expired and custom together' do
    expired_custom = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://expired-custom.com',
      slug: 'expired-custom'
    )
    expired_custom.update_column(:expires_at, 1.day.ago)

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://active-custom.com',
      slug: 'active-custom',
      expires_at: 1.day.from_now
    )

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://expired-generated.com'
    ).update_column(:expires_at, 1.day.ago)

    get '/api/v1/',
        params: { expired: true, custom: true, limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body['data'].length
    assert_equal 'https://expired-custom.com', body['data'][0]['long_url']
    assert_equal true, body['data'][0]['custom']
    assert_equal true, body['data'][0]['expired']
  end

  test 'filters urls by active status' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://active.com'
    )

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://inactive.com',
      active: false
    )

    get '/api/v1/',
        params: { active: true, limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body['data'].length
    assert_equal 'https://active.com', body['data'][0]['long_url']
  end

  test 'filters inactive urls when active=false' do
    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://active.com'
    )

    ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://inactive.com',
      active: false
    )

    get '/api/v1/',
        params: { active: false, limit: 10 },
        headers: @headers

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body['data'].length
    assert_equal 'https://inactive.com', body['data'][0]['long_url']
  end
end
