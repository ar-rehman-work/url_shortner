require 'test_helper'

class ShortUrlTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    ShortUrl.const_set(:HOST, 'http://localhost:3000') unless ShortUrl.const_defined?(:HOST)

    Rails.cache.clear
    clear_enqueued_jobs
    clear_performed_jobs

    @user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123'
    )
  end

  test 'should not save with nil long url' do
    short_url = ShortUrl.new(long_url: nil, user_id: @user.id)

    assert_not short_url.save
    assert_includes short_url.errors[:long_url], "can't be blank"
  end

  test 'should not save with empty long url' do
    short_url = ShortUrl.new(long_url: '', user_id: @user.id)

    assert_not short_url.save
    assert_includes short_url.errors[:long_url], "can't be blank"
  end

  test 'should not save with invalid long url' do
    short_url = ShortUrl.new(
      long_url: 'invalid-url',
      user_id: @user.id
    )

    assert_not short_url.save
    assert_includes short_url.errors[:long_url], 'must be a valid URL'
  end

  test 'should strip whitespace from long url' do
    short_url = ShortUrl.create!(
      long_url: '  https://example.com  ',
      user_id: @user.id
    )

    assert_equal 'https://example.com', short_url.long_url
  end

  test 'should save with valid long url and generate short code' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    short_url.reload

    assert short_url.persisted?
    assert_not_nil short_url.short_code
    assert_match(/\A[a-zA-Z0-9]+\z/, short_url.short_code)
  end

  test 'should generate correct url with short code' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    short_url.reload

    assert_equal "http://localhost:3000/s/#{short_url.short_code}", short_url.url
  end

  test 'should generate correct url with custom alias' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id,
      custom_alias: 'myalias'
    )

    assert_equal 'http://localhost:3000/myalias', short_url.url
  end

  test 'should not allow duplicate long url for same user' do
    ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    duplicate = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    assert_not duplicate.save
    assert_includes duplicate.errors[:long_url], 'has already been taken'
  end

  test 'should allow same long url for different users' do
    other_user = User.create!(
      name: 'Other User',
      email: 'other@example.com',
      password: 'password123'
    )

    ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    second = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: other_user.id
    )

    assert second.save
  end

  test 'should generate unique short codes' do
    url1 = ShortUrl.create!(
      long_url: 'https://a.com',
      user_id: @user.id
    )

    url2 = ShortUrl.create!(
      long_url: 'https://b.com',
      user_id: @user.id
    )

    url1.reload
    url2.reload

    assert_not_equal url1.short_code, url2.short_code
  end

  test 'should normalize custom alias to lowercase and strip' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id,
      custom_alias: '  MyAlias  '
    )

    assert_equal 'myalias', short_url.custom_alias
  end

  test 'custom alias becomes nil when blank after normalization' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id,
      custom_alias: '   '
    )

    assert_nil short_url.custom_alias
  end

  test 'should reject reserved custom alias' do
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id,
      custom_alias: 'login'
    )

    assert_not short_url.save
    assert_includes short_url.errors[:custom_alias], 'is reserved'
  end

  test 'should reject reserved custom alias after normalization' do
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id,
      custom_alias: '  LOGIN  '
    )

    assert_not short_url.save
    assert_includes short_url.errors[:custom_alias], 'is reserved'
  end

  test 'should reject custom alias with invalid characters' do
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id,
      custom_alias: 'my alias!'
    )

    assert_not short_url.save
    assert_includes short_url.errors[:custom_alias], 'must be a valid path'
  end

  test 'should allow valid custom alias characters' do
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id,
      custom_alias: 'my_alias-123'
    )

    assert short_url.valid?
  end

  test 'should not allow duplicate custom alias' do
    ShortUrl.create!(
      long_url: 'https://first.com',
      user_id: @user.id,
      custom_alias: 'samealias'
    )

    duplicate = ShortUrl.new(
      long_url: 'https://second.com',
      user_id: @user.id,
      custom_alias: 'samealias'
    )

    assert_not duplicate.save
    assert_includes duplicate.errors[:custom_alias], 'has already been taken'
  end

  test 'expired returns true when expires at is in past' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    short_url.update_column(:expires_at, 1.day.ago)

    assert short_url.expired?
  end

  test 'expired returns false when expires at is in future' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id,
      expires_at: 1.day.from_now
    )

    assert_not short_url.expired?
  end

  test 'expired returns false when expires at is nil' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    assert_not short_url.expired?
  end

  test 'expired scope returns only expired urls' do
    expired_url = ShortUrl.create!(
      long_url: 'https://expired.com',
      user_id: @user.id
    )

    expired_url.update_column(:expires_at, 1.day.ago)

    active_url = ShortUrl.create!(
      long_url: 'https://active.com',
      user_id: @user.id,
      expires_at: 1.day.from_now
    )

    results = ShortUrl.expired

    assert_includes results, expired_url
    assert_not_includes results, active_url
  end

  test 'active scope returns future and non expiring urls' do
    expired_url = ShortUrl.create!(
      long_url: 'https://expired.com',
      user_id: @user.id
    )
    expired_url.update_column(:expires_at, 1.day.ago)

    future_url = ShortUrl.create!(
      long_url: 'https://future.com',
      user_id: @user.id,
      expires_at: 1.day.from_now
    )

    non_expiring_url = ShortUrl.create!(
      long_url: 'https://non-expiring.com',
      user_id: @user.id
    )

    results = ShortUrl.active

    assert_includes results, future_url
    assert_includes results, non_expiring_url
    assert_not_includes results, expired_url
  end

  test 'custom scope returns only urls with custom alias' do
    custom_url = ShortUrl.create!(
      long_url: 'https://custom-scope.com',
      user_id: @user.id,
      custom_alias: 'custom-scope-path'
    )

    generated_url = ShortUrl.create!(
      long_url: 'https://generated-scope.com',
      user_id: @user.id
    )

    results = ShortUrl.custom

    assert_includes results, custom_url
    assert_not_includes results, generated_url
  end

  test 'generated scope returns urls without custom alias' do
    custom_url = ShortUrl.create!(
      long_url: 'https://custom-generated-scope.com',
      user_id: @user.id,
      custom_alias: 'generated-scope-path'
    )

    generated_url = ShortUrl.create!(
      long_url: 'https://generated-scope.com',
      user_id: @user.id
    )

    blank_alias_url = ShortUrl.create!(
      long_url: 'https://blank-scope.com',
      user_id: @user.id
    )
    blank_alias_url.update_column(:custom_alias, '')

    results = ShortUrl.generated

    assert_includes results, generated_url
    assert_includes results, blank_alias_url
    assert_not_includes results, custom_url
  end

  test 'should not allow past expires at during validation' do
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id,
      expires_at: 1.day.ago
    )

    assert_not short_url.save
    assert_includes short_url.errors[:expires_at].first, 'must be greater than'
  end

  test 'enqueues sync click counts job after create' do
    assert_enqueued_with(job: SyncClickCountsJob) do
      ShortUrl.create!(
        long_url: 'https://example.com',
        user_id: @user.id
      )
    end
  end

  test 'enqueues sync click counts job with short url id after create' do
    short_url = nil

    assert_enqueued_with(job: SyncClickCountsJob) do
      short_url = ShortUrl.create!(
        long_url: 'https://example.com',
        user_id: @user.id
      )
    end

    job = enqueued_jobs.last

    assert_equal SyncClickCountsJob, job[:job]
    assert_equal [short_url.id], job[:args]
  end

  test 'clears redirect cache for short code url' do
    short_url = ShortUrl.create!(
      long_url: 'https://cache-short-code.com',
      user_id: @user.id
    )

    short_url.reload

    cache_key = "short_url:s_#{short_url.short_code}"

    Rails.cache.expects(:delete).with(cache_key)

    short_url.send(:clear_redirect_cache)
  end

  test 'clears redirect cache for custom alias url' do
    short_url = ShortUrl.create!(
      long_url: 'https://cache-custom-alias.com',
      user_id: @user.id,
      custom_alias: 'custom-cache'
    )

    short_url.reload

    short_code_cache_key = "short_url:s_#{short_url.short_code}"
    custom_alias_cache_key = 'short_url:custom-cache'

    Rails.cache.expects(:delete).with(short_code_cache_key)
    Rails.cache.expects(:delete).with(custom_alias_cache_key)

    short_url.send(:clear_redirect_cache)
  end

  test 'destroys related click events when short url is destroyed' do
    short_url = ShortUrl.create!(
      long_url: 'https://click-events.com',
      user_id: @user.id
    )

    click_event = ClickEvent.create!(
      short_url: short_url,
      ip_address: '127.0.0.1'
    )

    short_url.destroy

    assert_not ClickEvent.exists?(click_event.id)
  end
end
