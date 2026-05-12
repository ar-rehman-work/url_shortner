require 'test_helper'

class ShortUrlTest < ActiveSupport::TestCase
  def setup
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

  test 'should save with valid long url' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    assert short_url.persisted?
    assert_not_nil short_url.short_code
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

  test 'should generate short code after create' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    short_url.reload

    assert_not_nil short_url.short_code
    assert_match(/\A[a-zA-Z0-9]+\z/, short_url.short_code)
  end

  test 'short code should be unique per record' do
    url1 = ShortUrl.create!(
      long_url: 'https://a.com',
      user_id: @user.id
    )

    url2 = ShortUrl.create!(
      long_url: 'https://b.com',
      user_id: @user.id
    )

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

  test 'should reject reserved custom alias' do
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id,
      custom_alias: 'login'
    )

    assert_not short_url.save
    assert_includes short_url.errors[:custom_alias], 'is reserved'
  end

  test 'expired? returns true when expires_at is in past' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    short_url.update_column(:expires_at, 1.day.ago)

    assert short_url.expired?
  end

  test 'expired? returns false when expires_at is in future' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id,
      expires_at: 1.day.from_now
    )

    assert_not short_url.expired?
  end

  test 'expired? returns false when expires_at is not present' do
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

  test 'active scope returns only non expired urls' do
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

    results = ShortUrl.active

    assert_includes results, active_url
    assert_not_includes results, expired_url
  end

  test 'should not allow past expires_at during validation' do
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id,
      expires_at: 1.day.ago
    )

    assert_not short_url.save
    assert_includes short_url.errors[:expires_at].first, 'must be greater than'
  end

  test 'custom alias becomes nil when blank after normalization' do
    short_url = ShortUrl.create!(
      long_url: 'https://example.com',
      user_id: @user.id,
      custom_alias: '   '
    )

    assert_nil short_url.custom_alias
  end
end