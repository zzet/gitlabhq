class AddServiceKeyServiceRelationshipModel < ActiveRecord::Migration
  def change
    create_table :service_keys_service_relationships do |t|
      t.integer :service_key_id, null: false
      t.integer :service_id, null: false
      t.boolean :push_access
      t.boolean :clone_access
      t.boolean :push_to_protected_access

      t.timestamps
    end
  end
end
