require 'test_helper'

class SyncClickCountsJobTest < ActiveJob::TestCase
  def setup
    REDIS.clear if REDIS.respond_to?(:clear)

    @user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123'
    )

    @short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example.com'
    )

    @short_url.update_columns(
      click_count: 0,
      last_click_at: nil
    )
  end

  test 'syncs click count for specific short url' do
    REDIS.incr("url:#{@short_url.id}:click_count")
    REDIS.incr("url:#{@short_url.id}:click_count")
    REDIS.set("url:#{@short_url.id}:last_click_at", 1.hour.ago.to_i)

    SyncClickCountsJob.perform_now(@short_url.id)

    @short_url.reload

    assert_equal 2, @short_url.click_count
    assert_not_nil @short_url.last_click_at
    assert_nil REDIS.getdel("url:#{@short_url.id}:click_count")
    assert_nil REDIS.getdel("url:#{@short_url.id}:last_click_at")
  end

  test 'adds redis click count to existing database click count' do
    @short_url.update!(click_count: 5)

    3.times do
      REDIS.incr("url:#{@short_url.id}:click_count")
    end

    REDIS.set("url:#{@short_url.id}:last_click_at", Time.current.to_i)

    SyncClickCountsJob.perform_now(@short_url.id)

    @short_url.reload

    assert_equal 8, @short_url.click_count
  end

  test 'updates last click at from redis timestamp' do
    timestamp = 30.minutes.ago.to_i

    REDIS.incr("url:#{@short_url.id}:click_count")
    REDIS.set("url:#{@short_url.id}:last_click_at", timestamp)

    SyncClickCountsJob.perform_now(@short_url.id)

    @short_url.reload

    assert_equal Time.zone.at(timestamp).to_i, @short_url.last_click_at.to_i
  end

  test 'uses current time when last click timestamp is missing' do
    travel_to Time.current do
      REDIS.incr("url:#{@short_url.id}:click_count")

      SyncClickCountsJob.perform_now(@short_url.id)

      @short_url.reload

      assert_not_nil @short_url.last_click_at
      assert_in_delta Time.current.to_i, @short_url.last_click_at.to_i, 2
    end
  end

  test 'does nothing when click count is zero' do
    SyncClickCountsJob.perform_now(@short_url.id)

    @short_url.reload

    assert_equal 0, @short_url.click_count
    assert_nil @short_url.last_click_at
  end

  test 'syncs all active click urls when no id is given' do
    second_short_url = ShortUrl.create!(
      user_id: @user.id,
      long_url: 'https://example-two.com'
    )

    second_short_url.update_columns(
      click_count: 0,
      last_click_at: nil
    )

    REDIS.sadd('active_click_urls', @short_url.id)
    REDIS.sadd('active_click_urls', second_short_url.id)

    2.times { REDIS.incr("url:#{@short_url.id}:click_count") }
    4.times { REDIS.incr("url:#{second_short_url.id}:click_count") }

    REDIS.set("url:#{@short_url.id}:last_click_at", 1.hour.ago.to_i)
    REDIS.set("url:#{second_short_url.id}:last_click_at", 30.minutes.ago.to_i)

    SyncClickCountsJob.perform_now

    @short_url.reload
    second_short_url.reload

    assert_equal 2, @short_url.click_count
    assert_equal 4, second_short_url.click_count
    assert_empty REDIS.smembers('active_click_urls')
  end

  test 'removes active url from redis set after syncing all urls' do
    REDIS.sadd('active_click_urls', @short_url.id)
    REDIS.incr("url:#{@short_url.id}:click_count")
    REDIS.set("url:#{@short_url.id}:last_click_at", Time.current.to_i)

    SyncClickCountsJob.perform_now

    assert_empty REDIS.smembers('active_click_urls')
  end

  test 'does not remove active url from redis set when syncing specific short url' do
    REDIS.sadd('active_click_urls', @short_url.id)
    REDIS.incr("url:#{@short_url.id}:click_count")
    REDIS.set("url:#{@short_url.id}:last_click_at", Time.current.to_i)

    SyncClickCountsJob.perform_now(@short_url.id)

    assert_includes REDIS.smembers('active_click_urls'), @short_url.id.to_s
  end

  test 'does not fail when short url does not exist' do
    REDIS.incr('url:999999:click_count')
    REDIS.set('url:999999:last_click_at', Time.current.to_i)

    assert_nothing_raised do
      SyncClickCountsJob.perform_now(999999)
    end
  end
end
