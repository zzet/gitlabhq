class CreateServiceConfigurationJenkins < ActiveRecord::Migration
  def change
    create_table :service_configuration_jenkins do |t|
      t.integer :service_id
      t.string :host
      t.string :push_path
      t.string :merge_request_path
      t.text :branches
      t.boolean :merge_request_enabled

      t.timestamps
    end
  end
end
