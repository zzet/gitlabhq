class CreateServiceConfigurationFlowdocks < ActiveRecord::Migration
  def change
    create_table :service_configuration_flowdocks do |t|
      t.integer :service_id
      t.string :service_type
      t.string :token

      t.timestamps
    end
  end
end
