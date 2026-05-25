class CreateClickEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :click_events do |t|
      t.references :short_url, null: false, foreign_key: true
      t.string :ip_address
      t.text :user_agent
      t.text :referrer
      t.string :country
      t.string :city
      t.string :device_type
      t.string :browser
      t.string :os

      t.timestamps
    end
  end
end
