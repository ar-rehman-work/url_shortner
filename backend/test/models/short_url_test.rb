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
    short_url = ShortUrl.new(
      long_url: 'https://example.com',
      user_id: @user.id
    )

    assert short_url.save
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

    assert_not_nil short_url.short_code
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
end
