require 'test_helper'

class ClickEventTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123'
    )

    @short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )
  end

  test 'creates click event with valid required attributes' do
    click_event = ClickEvent.new(
      short_url: @short_url,
      ip_address: '127.0.0.1'
    )

    assert click_event.valid?
    assert click_event.save
  end

  test 'requires short url' do
    click_event = ClickEvent.new(
      ip_address: '127.0.0.1'
    )

    assert_not click_event.valid?
    assert_includes click_event.errors[:short_url], 'must exist'
  end

  test 'requires ip address' do
    click_event = ClickEvent.new(
      short_url: @short_url,
      ip_address: nil
    )

    assert_not click_event.valid?
    assert_includes click_event.errors[:ip_address], "can't be blank"
  end

  test 'rejects blank ip address' do
    click_event = ClickEvent.new(
      short_url: @short_url,
      ip_address: ''
    )

    assert_not click_event.valid?
    assert_includes click_event.errors[:ip_address], "can't be blank"
  end

  test 'allows optional analytics fields to be blank' do
    click_event = ClickEvent.new(
      short_url: @short_url,
      ip_address: '127.0.0.1',
      user_agent: nil,
      referrer: nil,
      browser: nil,
      os: nil,
      device_type: nil,
      country: nil,
      city: nil
    )

    assert click_event.valid?
  end

  test 'belongs to short url' do
    click_event = ClickEvent.create!(
      short_url: @short_url,
      ip_address: '127.0.0.1'
    )

    assert_equal @short_url, click_event.short_url
  end

  test 'short url can have many click events' do
    ClickEvent.create!(
      short_url: @short_url,
      ip_address: '127.0.0.1'
    )

    ClickEvent.create!(
      short_url: @short_url,
      ip_address: '192.0.2.1'
    )

    assert_equal 2, @short_url.click_events.count
  end

  test 'stores request metadata' do
    click_event = ClickEvent.create!(
      short_url: @short_url,
      ip_address: '127.0.0.1',
      user_agent: 'Mozilla/5.0',
      referrer: 'https://example-referrer.com',
      browser: 'Chrome',
      os: 'Windows',
      device_type: 'Desktop',
      country: 'Unknown',
      city: 'Unknown'
    )

    assert_equal '127.0.0.1', click_event.ip_address
    assert_equal 'Mozilla/5.0', click_event.user_agent
    assert_equal 'https://example-referrer.com', click_event.referrer
    assert_equal 'Chrome', click_event.browser
    assert_equal 'Windows', click_event.os
    assert_equal 'Desktop', click_event.device_type
    assert_equal 'Unknown', click_event.country
    assert_equal 'Unknown', click_event.city
  end

  test 'destroys click events when short url is destroyed' do
    click_event = ClickEvent.create!(
      short_url: @short_url,
      ip_address: '127.0.0.1'
    )

    @short_url.destroy

    assert_not ClickEvent.exists?(click_event.id)
  end
end
