class CreateServiceConfigurationHipchats < ActiveRecord::Migration
  def change
    create_table :service_configuration_hipchats do |t|
      t.integer :service_id
      t.string :service_type
      t.string :token
      t.string :room

      t.timestamps
    end
  end
end
