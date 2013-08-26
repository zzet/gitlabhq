class CreateDeployKeyServiceRelationships < ActiveRecord::Migration
  def change
    create_table :deploy_key_service_relationships do |t|
      t.integer :deploy_key_id
      t.integer :service_id

      t.timestamps
    end
  end
end
