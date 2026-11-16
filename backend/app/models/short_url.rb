class ShortUrl < ApplicationRecord
  belongs_to :user
  has_many :click_events, dependent: :destroy

  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :custom, -> { where.not(custom_alias: [nil, '']) }
  scope :generated, -> { where(custom_alias: [nil, '']) }

  after_create :set_short_code
  after_commit :clear_redirect_cache, on: [:create, :update, :destroy]

  before_validation :normalize_long_url
  before_validation :normalize_custom_alias

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
            with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
            message: 'must be a valid URL'
          }

  BASE62 = '5jRkZq0aF9nM1bXc8VtYp3H6sD2uG7wL4oE1KzN9mQxA0BfC8dPjS2hUeR6yW'.freeze

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def url
    path = custom_alias.presence || short_code

    "#{HOST}/#{path}"
  end

  private

  def set_short_code
    update_column(:short_code, encode_base62(id)) if short_code.blank?
  end

  def clear_redirect_cache
    codes = [
      short_code,
      custom_alias,
      *previous_changes.fetch('short_code', []),
      *previous_changes.fetch('custom_alias', [])
    ].compact.uniq

    codes.each do |code|
      Rails.cache.delete("sc:#{code}")
    end
  end

  def encode_base62(num)
    return '0' if num == 0

    base = BASE62.length
    encoded = ''

    while num > 0
      encoded << BASE62[num % base]
      num /= base
    end

    encoded.reverse
  end

  def normalize_long_url
    self.long_url = long_url.strip if long_url.present?
  end

  def normalize_custom_alias
    self.custom_alias = custom_alias.to_s.strip.downcase.presence

    return if custom_alias.blank?
  end
end
