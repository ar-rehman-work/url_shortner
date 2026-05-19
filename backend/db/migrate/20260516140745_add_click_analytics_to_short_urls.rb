class AddClickAnalyticsToShortUrls < ActiveRecord::Migration[8.1]
  def change
    add_column :short_urls, :click_count, :integer, default: 0, null: false
    add_column :short_urls, :last_click_at, :datetime
  end
end
