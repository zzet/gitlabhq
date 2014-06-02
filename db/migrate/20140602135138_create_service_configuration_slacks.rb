class CreateServiceConfigurationSlacks < ActiveRecord::Migration
  def change
    create_table :service_configuration_slacks do |t|
      t.integer :service_id
      t.string :service_type
      t.string :token
      t.string :room
      t.string :subdomain

      t.timestamps
    end
  end
end
