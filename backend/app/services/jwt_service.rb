class JwtService
  SECRET = Rails.application.credentials.secret_key_base

  def self.encode(payload)
    JWT.encode(payload, SECRET)
  end

  def self.decode(token)
    JWT.decode(token, SECRET)[0]
  rescue
    nil
  end
end
