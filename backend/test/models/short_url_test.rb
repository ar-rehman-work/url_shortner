require 'test_helper'

class ShortUrlTest < ActiveSupport::TestCase
  test 'should not save with nil long url' do
    short_url = ShortUrl.new(long_url: nil)

    assert_not short_url.save
    assert_includes short_url.errors[:long_url], "can't be blank"
  end

  test 'should not save with empty long url' do
    short_url = ShortUrl.new(long_url: '')

    assert_not short_url.save
    assert_includes short_url.errors[:long_url], "can't be blank"
  end


  test 'should generate short code after create' do
    short_url = short_urls(:one)

    assert_not_nil short_url.short_code
  end

  test 'short code should be unique' do
    url1 = short_urls(:one)
    url2 = short_urls(:two)

    assert_not_equal url1.short_code, url2.short_code
  end

  test 'should not allow duplicate long urls' do
    ShortUrl.create!(long_url: 'https://www.example.com')
    duplicate = ShortUrl.new(long_url: 'https://www.example.com')

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:long_url], 'has already been taken'
  end

  test 'should match Base62 encoding logic' do
    short_url = ShortUrl.create!(long_url: 'https://www.example.com')

    encoded = short_url.send(:encode_base62, short_url.id)

    assert_equal short_url.short_code, encoded
  end
end