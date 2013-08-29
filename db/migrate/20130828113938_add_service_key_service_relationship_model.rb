class AddServiceKeyServiceRelationshipModel < ActiveRecord::Migration
  def change
    create_table :service_key_service_relationships do |t|
      t.integer :service_key_id, null: false
      t.integer :service_id, null: false
      t.string :code_access_state

      t.timestamps
    end
  end
end
