class CreateGlobalSettingsEmailDomains < ActiveRecord::Migration
  def change
    create_table :global_setting_email_domains do |t|
      t.integer :global_settings_id
      t.string :domain
      t.string :description

      t.timestamps
    end
  end
end
