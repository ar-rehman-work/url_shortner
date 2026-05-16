class AddExpiresAtAndCustomAliasToShortUrls < ActiveRecord::Migration[8.1]
  def change
    add_column :short_urls, :expires_at, :datetime
    add_column :short_urls, :custom_alias, :string

    add_index :short_urls, :custom_alias, unique: true, where: 'custom_alias IS NOT NULL'
  end
end
