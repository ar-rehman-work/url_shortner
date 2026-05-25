require 'test_helper'

class TrackClickJobTest < ActiveJob::TestCase
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

  test 'creates click event for valid short url' do
    assert_difference 'ClickEvent.count', 1 do
      TrackClickJob.perform_now(
        @short_url.id,
        '127.0.0.1',
        'Mozilla/5.0',
        'https://example-referrer.com'
      )
    end

    click_event = ClickEvent.last

    assert_equal @short_url, click_event.short_url
    assert_equal '127.0.0.1', click_event.ip_address
    assert_equal 'Mozilla/5.0', click_event.user_agent
    assert_equal 'https://example-referrer.com', click_event.referrer
  end

  test 'does not create click event when short url does not exist' do
    assert_no_difference 'ClickEvent.count' do
      TrackClickJob.perform_now(
        999_999,
        '127.0.0.1',
        'Mozilla/5.0',
        nil
      )
    end
  end

  test 'stores browser and os metadata' do
    user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'

    TrackClickJob.perform_now(
      @short_url.id,
      '127.0.0.1',
      user_agent,
      nil
    )

    click_event = ClickEvent.last

    assert_not_nil click_event.browser
    assert_not_nil click_event.os
  end

  test 'stores desktop device type for desktop user agent' do
    user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'

    TrackClickJob.perform_now(
      @short_url.id,
      '127.0.0.1',
      user_agent,
      nil
    )

    assert_equal 'desktop', ClickEvent.last.device_type
  end

  test 'stores mobile device type for mobile user agent' do
    user_agent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148'

    TrackClickJob.perform_now(
      @short_url.id,
      '127.0.0.1',
      user_agent,
      nil
    )

    assert_equal 'mobile', ClickEvent.last.device_type
  end

  test 'stores tablet device type for tablet user agent' do
    user_agent = 'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148'

    TrackClickJob.perform_now(
      @short_url.id,
      '127.0.0.1',
      user_agent,
      nil
    )

    assert_equal 'tablet', ClickEvent.last.device_type
  end

  test 'stores bot device type for bot user agent' do
    user_agent = 'Googlebot/2.1'

    TrackClickJob.perform_now(
      @short_url.id,
      '127.0.0.1',
      user_agent,
      nil
    )

    assert_equal 'bot', ClickEvent.last.device_type
  end

  test 'allows nil user agent' do
    assert_difference 'ClickEvent.count', 1 do
      TrackClickJob.perform_now(
        @short_url.id,
        '127.0.0.1',
        nil,
        nil
      )
    end

    click_event = ClickEvent.last

    assert_equal @short_url, click_event.short_url
    assert_equal '127.0.0.1', click_event.ip_address
    assert_nil click_event.user_agent
  end

  test 'allows nil referrer' do
    TrackClickJob.perform_now(
      @short_url.id,
      '127.0.0.1',
      'Mozilla/5.0',
      nil
    )

    assert_nil ClickEvent.last.referrer
  end

  test 'logs error and does not raise when click event creation fails' do
    logger = Class.new do
      attr_reader :messages

      def initialize
        @messages = []
      end

      def error(message)
        @messages << message
      end
    end.new

    original_logger = Rails.logger
    Rails.logger = logger

    assert_nothing_raised do
      TrackClickJob.perform_now(
        @short_url.id,
        nil,
        'Mozilla/5.0',
        nil
      )
    end

    assert logger.messages.any? { |message| message.include?('TrackClickJob failed:') }
  ensure
    Rails.logger = original_logger
  end
end
