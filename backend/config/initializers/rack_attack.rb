class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')
  )

  SHORTEN_PATH = '/shorten'

  throttle('url_creation/user', limit: 40, period: 1.hour) do |req|
    next unless req.path == SHORTEN_PATH && req.post?

    token = req.get_header('HTTP_AUTHORIZATION')&.split(' ')&.last
    decoded = JwtService.decode(token)

    decoded[:user_id] || decoded['user_id']
  rescue StandardError
    nil
  end

  # Future anonymous support
  # throttle('url_creation/anonymous_ip', limit: 20, period: 1.hour) do |req|
  #   next unless req.path == SHORTEN_PATH && req.post?
  #
  #   token = req.get_header('HTTP_AUTHORIZATION')&.split(' ')&.last
  #
  #   begin
  #     JwtService.decode(token)
  #     nil
  #   rescue StandardError
  #     req.ip
  #   end
  # end

  self.throttled_responder = lambda do |_request|
    [
      429,
      { 'Content-Type' => 'application/json' },
      [{ error: 'Rate limit exceeded. Please try again later.' }.to_json]
    ]
  end
end
