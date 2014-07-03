class CreateServiceConfigurationRedmines < ActiveRecord::Migration
  def change
    create_table :service_configuration_redmines do |t|
      t.string :domain
      t.string :web_hook_path
      t.integer :service_id
      t.string :service_type

      t.timestamps
    end
  end
end
