class ShortUrl < ApplicationRecord
  belongs_to :user
  has_many :click_events, dependent: :destroy

  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  scope :unexpired, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :custom, -> { where(custom: true) }
  scope :generated, -> { where(custom: false) }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  after_create :set_short_code
  after_commit :clear_redirect_cache, on: [:create, :update, :destroy]

  before_validation :normalize_long_url
  before_validation :normalize_slug
  before_validation :set_custom_flag, on: :create

  validates :expires_at, comparison: { greater_than: -> { Time.current } }, allow_nil: true
  validates :slug,
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

  BASE62 = 'ilTg5vJrIkZqOaFnMbXcVtYp3HsDuG7wL4oE1KzN9mQxA0BfC8dPjS2hUeR6yW'.freeze

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def url
    return if slug.blank?

    "#{HOST}/#{slug}"
  end

  private

  def set_short_code
    code = encode_base62(id)

    update_columns(short_code: code, slug: custom? ? slug : code)
  end

  def clear_redirect_cache
    [
      slug,
      *previous_changes.fetch('slug', [])
    ].compact.uniq.each do |identifier|
      Rails.cache.delete("sc:#{identifier}")
    end
  end

  def encode_base62(num)
    return '0' if num.zero?

    base = BASE62.length
    encoded = ''

    while num > 0
      encoded += BASE62[num % base]
      num /= base
    end

    encoded.reverse
  end

  def normalize_long_url
    self.long_url = long_url.strip if long_url.present?
  end

  def normalize_slug
    self.slug = slug.to_s.strip.presence
  end

  def set_custom_flag
    self.custom = slug.present?
  end
end
