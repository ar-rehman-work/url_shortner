class ShortUrl < ApplicationRecord
  belongs_to :user

  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }

  after_create :set_short_code

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

  BASE62 = '5jRkZq0aF9nM1bXc8VtYp3H6sD2uG7wL4oE1KzN9mQxA0BfC8dPjS2hUeR6yW'.freeze
  RESERVED_SHORT_CODES = %w[shorten login signup].freeze

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  private

  def set_short_code
    update_column(:short_code, encode_base62(id)) if short_code.blank?
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

  def check_custom_alias
    self.custom_alias = custom_alias.to_s.strip.downcase.presence

    return if custom_alias.blank?

    if RESERVED_SHORT_CODES.include?(custom_alias)
      errors.add(:custom_alias, 'is reserved')
    end
  end
end
