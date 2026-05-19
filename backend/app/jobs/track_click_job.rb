class TrackClickJob < ApplicationJob
  queue_as :default

  def perform(short_url_id, ip_address, user_agent, referrer)
    short_url = ShortUrl.find_by(id: short_url_id)
    return unless short_url

    browser_info = Browser.new(user_agent)
    location = Geocoder.search(ip_address).first

    ClickEvent.create!(
      short_url: short_url,
      ip_address: ip_address,
      user_agent: user_agent,
      referrer: referrer,
      country: location&.country,
      city: location&.city,
      device_type: device_type(browser_info),
      browser: browser_info.name,
      os: browser_info.platform.name
    )
  rescue StandardError => e
    Rails.logger.error("TrackClickJob failed: #{e.message}")
  end

  private

  def device_type(browser_info)
    return 'bot' if browser_info.bot?
    return 'mobile' if browser_info.device.mobile?
    return 'tablet' if browser_info.device.tablet?

    'desktop'
  end
end
