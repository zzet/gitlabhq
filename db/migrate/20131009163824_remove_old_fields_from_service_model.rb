class RemoveOldFieldsFromServiceModel < ActiveRecord::Migration
  def change
    remove_column :services, :token
    remove_column :services, :active
    remove_column :services, :project_url
    remove_column :services, :subdomain
    remove_column :services, :room
  end
end
