class CreateServiceConfigurationAssemblas < ActiveRecord::Migration
  def change
    create_table :service_configuration_assemblas do |t|
      t.string :token
      t.integer :service_id
      t.string :service_type

      t.timestamps
    end
  end
end
