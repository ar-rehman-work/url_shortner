class ShortUrl < ApplicationRecord
  belongs_to :user

  after_create :set_short_code

  validates :long_url, presence: true, uniqueness: { scope: :user_id }

  BASE62 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'

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
end
