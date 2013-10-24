class CreateServiceConfigurationCampfires < ActiveRecord::Migration
  def change
    create_table :service_configuration_campfires do |t|
      t.integer :service_id
      t.string :service_type
      t.string :token
      t.string :subdomain
      t.string :room

      t.timestamps
    end
  end
end
