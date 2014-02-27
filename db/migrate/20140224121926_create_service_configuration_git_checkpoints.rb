class CreateServiceConfigurationGitCheckpoints < ActiveRecord::Migration
  def change
    create_table :service_configuration_git_checkpoints do |t|
      t.integer :service_id
      t.string :service_type
      t.string :token
      t.string :domain
      t.string :system_hook_path
      t.string :web_hook_path

      t.timestamps
    end
  end
end
