class ShortUrl < ApplicationRecord
  belongs_to :user

  after_create :set_short_code

  before_validation :normalize_long_url

  validates :long_url,
          presence: true,
          uniqueness: { scope: :user_id },
          format: {
            with: /\Ahttps?:\/\/.+\..+\z/,
            message: 'must be a valid URL'
          }

  BASE62 = '5jRkZq0aF9nM1bXc8VtYp3H6sD2uG7wL4oE1KzN9mQxA0BfC8dPjS2hUeR6yW'.freeze

  private

  def set_short_code
    update_column(:short_code, encode_base62(id))
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
end
