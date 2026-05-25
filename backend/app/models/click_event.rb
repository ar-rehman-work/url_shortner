class ClickEvent < ApplicationRecord
  belongs_to :short_url

  validates :ip_address, presence: true
end
