class CreateShortUrls < ActiveRecord::Migration[8.1]
  def change
    create_table :short_urls do |t|
      t.string :short_code
      t.text :long_url, null: false

      t.timestamps
    end

    add_index :short_urls, :short_code, unique: true
  end
end