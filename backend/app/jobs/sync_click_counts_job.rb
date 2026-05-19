class SyncClickCountsJob < ApplicationJob
  queue_as :default

  def perform(short_url_id = nil)
    if short_url_id.present?
      sync_short_url(short_url_id)
    else
      REDIS.smembers('active_click_urls').each do |short_url_id|
        sync_short_url(short_url_id)
        REDIS.srem('active_click_urls', short_url_id)
      end
    end
  end

  private

  def sync_short_url(short_url_id)
    count = REDIS.getdel("url:#{short_url_id}:click_count").to_i
    return if count.zero?

    last_click_at = REDIS.getdel("url:#{short_url_id}:last_click_at")

    ShortUrl.where(id: short_url_id).update_all(
      [
        'click_count = click_count + ?, last_click_at = ?',
        count,
        last_click_at.present? ? Time.zone.at(last_click_at.to_i) : Time.current
      ]
    )
  end
end
