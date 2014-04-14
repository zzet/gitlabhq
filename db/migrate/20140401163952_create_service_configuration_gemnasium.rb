class CreateServiceConfigurationGemnasium < ActiveRecord::Migration
  def change
    create_table :service_configuration_gemnasia do |t|
      t.string :token
      t.string :api_key
      t.integer :service_id
      t.string :service_type

      t.timestamps
    end
  end
end
