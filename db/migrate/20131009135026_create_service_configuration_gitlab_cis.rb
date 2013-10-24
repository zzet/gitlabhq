class CreateServiceConfigurationGitlabCis < ActiveRecord::Migration
  def change
    create_table :service_configuration_gitlab_cis do |t|
      t.integer :service_id
      t.string :service_type
      t.string :token
      t.string :project_url

      t.timestamps
    end
  end
end
