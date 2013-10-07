class CreateServiceConfigurationBuildFaces < ActiveRecord::Migration
  def change
    create_table :service_configuration_build_faces do |t|
      t.integer :service_id
      t.string :service_type
      t.string :token
      t.string :domain
      t.string :system_hook_path

      t.timestamps
    end
  end
end
