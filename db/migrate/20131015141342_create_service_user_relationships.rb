class CreateServiceUserRelationships < ActiveRecord::Migration
  def change
    create_table :service_user_relationships do |t|
      t.integer :service_id
      t.integer :user_id

      t.timestamps
    end
  end
end
