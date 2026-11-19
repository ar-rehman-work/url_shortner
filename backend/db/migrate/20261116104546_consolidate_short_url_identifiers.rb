
class ConsolidateShortUrlIdentifiers < ActiveRecord::Migration[8.1]
  def up
    add_column :short_urls, :custom, :boolean, default: false, null: false
    add_column :short_urls, :active, :boolean, default: true, null: false
    add_column :short_urls, :slug, :string
    add_index :short_urls, :slug, unique: true, where: 'slug IS NOT NULL'

    execute <<~SQL
      UPDATE short_urls
      SET
        slug = CASE
          WHEN NULLIF(BTRIM(custom_alias), '') IS NOT NULL
            THEN BTRIM(custom_alias)
          ELSE NULL
        END,
        custom = NULLIF(BTRIM(custom_alias), '') IS NOT NULL,
        active = FALSE
      WHERE id IN (
        SELECT generated.id
        FROM short_urls AS generated
        INNER JOIN short_urls AS custom
          ON generated.short_code = custom.custom_alias
         AND generated.id <> custom.id
        WHERE NULLIF(BTRIM(custom.custom_alias), '') IS NOT NULL

        UNION

        SELECT custom.id
        FROM short_urls AS generated
        INNER JOIN short_urls AS custom
          ON generated.short_code = custom.custom_alias
         AND generated.id <> custom.id
        WHERE NULLIF(BTRIM(custom.custom_alias), '') IS NOT NULL
      );

      UPDATE short_urls
      SET
        slug = CASE
          WHEN NULLIF(BTRIM(custom_alias), '') IS NOT NULL
            THEN BTRIM(custom_alias)
          ELSE short_code
        END,
        custom = NULLIF(BTRIM(custom_alias), '') IS NOT NULL
      WHERE active = TRUE;
    SQL

    remove_index :short_urls, name: 'index_short_urls_on_custom_alias'
    remove_column :short_urls, :custom_alias
  end

  def down
    add_column :short_urls, :custom_alias, :string
    add_index :short_urls, :custom_alias, unique: true, where: 'custom_alias IS NOT NULL'

    execute <<~SQL
      UPDATE short_urls
      SET custom_alias = CASE
        WHEN custom THEN slug
        ELSE NULL
      END;
    SQL

    remove_index :short_urls, :slug
    remove_column :short_urls, :slug
    remove_column :short_urls, :custom
    remove_column :short_urls, :active
  end
end
