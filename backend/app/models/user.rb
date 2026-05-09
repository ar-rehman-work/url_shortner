class User < ApplicationRecord
  has_secure_password

  has_many :short_urls, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
