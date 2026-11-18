
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
    assert_equal short_url.short_code, short_url.slug
    assert_not short_url.custom
  end

  test 'should generate correct url with generated slug' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    short_url.reload

    assert_equal(
      "http://localhost:3000/#{short_url.slug}",
      short_url.url
    )
  end

  test 'should generate correct url with custom slug' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id,
      slug: 'myalias'
    )

    short_url.reload

    assert_equal 'http://localhost:3000/myalias', short_url.url
    assert_not_nil short_url.short_code
    assert_equal 'myalias', short_url.slug
    assert short_url.custom
  end

  test 'should return nil url when slug is nil' do
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id,
      slug: nil
    )

    assert_nil short_url.url
  end

  test 'should return nil url when slug is blank' do
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id,
      slug: '   '
    )

    assert_nil short_url.url
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
    assert_not_equal url1.slug, url2.slug
  end

  test 'should normalize custom slug to strip whitespace' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id,
      slug: '  MyAlias  '
    )

    assert_equal 'MyAlias', short_url.slug
    assert short_url.custom
  end

  test 'should set slug with short code when blank slug is provided on creation' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id,
      slug: '   '
    )

    short_url.reload

    assert_not_nil short_url.short_code
    assert_equal short_url.short_code, short_url.slug
    assert_not short_url.custom
  end

  test 'should change existing custom alias to another custom alias' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id,
      slug: 'old-alias'
    )

    short_url.reload
    original_short_code = short_url.short_code

    short_url.update!(slug: 'new-alias')
    short_url.reload

    assert_equal 'new-alias', short_url.slug
    assert_equal original_short_code, short_url.short_code
    assert short_url.custom
  end

  test 'should change generated slug to custom alias' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    short_url.reload
    original_short_code = short_url.short_code

    short_url.update!(slug: 'MyAlias')
    short_url.reload

    assert_equal 'MyAlias', short_url.slug
    assert_equal original_short_code, short_url.short_code
    assert short_url.custom
  end

  test 'should restore generated slug when custom alias is removed' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id,
      slug: 'myalias'
    )

    short_url.reload
    original_short_code = short_url.short_code

    short_url.update!(slug: '')
    short_url.reload

    assert_equal original_short_code, short_url.slug
    assert_equal original_short_code, short_url.short_code
    assert_not short_url.custom
  end

  test 'should reject custom slug with invalid characters' do
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id,
      slug: 'my alias!'
    )

    assert_not short_url.save
    assert_includes short_url.errors[:slug], 'must be a valid path'
  end

  test 'should allow valid custom slug characters' do
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id,
      slug: 'my_alias-123'
    )

    assert short_url.valid?
  end

  test 'should not allow duplicate slug' do
    ShortUrl.create!(
      long_url: 'https://first.com',
      user_id: @user.id,
      slug: 'samealias'
    )

    duplicate = ShortUrl.new(
      long_url: 'https://second.com',
      user_id: @user.id,
      slug: 'samealias'
    )

    assert_not duplicate.save
    assert_includes duplicate.errors[:slug], 'has already been taken'
  end

  test 'should set active to true by default' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    assert short_url.active
  end

  test 'active scope returns only active urls' do
    active_url = ShortUrl.create!(
      long_url: 'https://active.com',
      user_id: @user.id
    )

    inactive_url = ShortUrl.create!(
      long_url: 'https://inactive.com',
      user_id: @user.id
    )
    inactive_url.update!(active: false)

    results = ShortUrl.active

    assert_includes results, active_url
    assert_not_includes results, inactive_url
  end

  test 'inactive scope returns only inactive urls' do
    active_url = ShortUrl.create!(
      long_url: 'https://active.com',
      user_id: @user.id
    )

    inactive_url = ShortUrl.create!(
      long_url: 'https://inactive.com',
      user_id: @user.id
    )
    inactive_url.update!(active: false)

    results = ShortUrl.inactive

    assert_includes results, inactive_url
    assert_not_includes results, active_url
  end

  test 'expired returns true when expires at is in the past' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    short_url.update_column(:expires_at, 1.day.ago)
    short_url.reload

    assert short_url.expired?
  end

  test 'expired returns false when expires at is in the future' do
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

    unexpired_url = ShortUrl.create!(
      long_url: 'https://unexpired.com',
      user_id: @user.id,
      expires_at: 1.day.from_now
    )

    results = ShortUrl.expired

    assert_includes results, expired_url
    assert_not_includes results, unexpired_url
  end

  test 'unexpired scope returns future and non-expiring urls' do
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

    results = ShortUrl.unexpired

    assert_includes results, future_url
    assert_includes results, non_expiring_url
    assert_not_includes results, expired_url
  end

  test 'custom scope returns only custom urls' do
    custom_url = ShortUrl.create!(
      long_url: 'https://custom-scope.com',
      user_id: @user.id,
      slug: 'custom-scope-path'
    )

    generated_url = ShortUrl.create!(
      long_url: 'https://generated-scope.com',
      user_id: @user.id
    )

    results = ShortUrl.custom

    assert_includes results, custom_url
    assert_not_includes results, generated_url
  end

  test 'generated scope returns only generated urls' do
    custom_url = ShortUrl.create!(
      long_url: 'https://custom-generated-scope.com',
      user_id: @user.id,
      slug: 'generated-scope-path'
    )

    generated_url = ShortUrl.create!(
      long_url: 'https://generated-scope.com',
      user_id: @user.id
    )

    results = ShortUrl.generated

    assert_includes results, generated_url
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

  test 'clears redirect cache for generated slug' do
    short_url = ShortUrl.create!(
      long_url: 'https://cache-generated.com',
      user_id: @user.id
    )

    short_url.reload

    Rails.cache.expects(:delete).with("sc:#{short_url.slug}")

    short_url.send(:clear_redirect_cache)
  end

  test 'clears redirect cache for custom slug' do
    short_url = ShortUrl.create!(
      long_url: 'https://cache-custom.com',
      user_id: @user.id,
      slug: 'custom-cache'
    )

    short_url.reload

    Rails.cache.expects(:delete).with('sc:custom-cache')

    short_url.send(:clear_redirect_cache)
  end

  test 'clears redirect cache for both old and new slugs' do
    short_url = ShortUrl.create!(
      long_url: 'https://cache-update.com',
      user_id: @user.id,
      slug: 'old-slug'
    )

    short_url.update!(slug: 'new-slug')

    Rails.cache.expects(:delete).with('sc:old-slug')
    Rails.cache.expects(:delete).with('sc:new-slug')

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
