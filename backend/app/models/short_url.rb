class ShortUrl < ApplicationRecord
  belongs_to :user
  has_many :click_events, dependent: :destroy

  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :custom, -> { where.not(custom_alias: [nil, '']) }
  scope :generated, -> { where(custom_alias: [nil, '']) }

  after_create :set_short_code
  after_commit :clear_redirect_cache

  before_validation :normalize_long_url
  before_validation :check_custom_alias

  validates :expires_at, comparison: { greater_than: -> { Time.current } }, allow_nil: true
  validates :custom_alias,
          allow_nil: true,
          uniqueness: true,
          format: {
            with: /\A[a-zA-Z0-9_-]+\z/,
            message: 'must be a valid path'
          }
  validates :long_url,
          presence: true,
          uniqueness: { scope: :user_id },
          format: {
            with: /\Ahttps?:\/\/.+\..+\z/,
            message: 'must be a valid URL'
          }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def url
    path = if custom_alias.present?
      "a/#{custom_alias}"
    else
      "s/#{short_code}"
    end

    "#{HOST}/#{path}"
  end

  private

  def set_short_code
    update_column(:short_code, encode_base62(id)) if short_code.blank?
  end

  def clear_redirect_cache
    SyncClickCountsJob.perform_later(id)

    Rails.cache.delete("short_url:s_#{short_code}") if short_code.present?
    Rails.cache.delete("short_url:#{custom_alias}") if custom_alias.present?
  end

  def encode_base62(num)
    return '0' if num == 0

    charset = ENV.fetch('SHORT_URL_CHARSET')
    base = charset.length
    encoded = ''

    while num > 0
      encoded << charset[num % base]
      num /= base
    end

    encoded.reverse
  end

  def normalize_long_url
    self.long_url = long_url.strip if long_url.present?
  end

  def check_custom_alias
    self.custom_alias = custom_alias.to_s.strip.downcase.presence

    return if custom_alias.blank?
  end
end
