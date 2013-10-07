class CreateServiceHierarchies < ActiveRecord::Migration
  def change
    create_table :service_hierarchies, :id => false do |t|
      t.integer  :ancestor_id, :null => false   # ID of the parent/grandparent/great-grandparent/... service
      t.integer  :descendant_id, :null => false # ID of the target service
      t.integer  :generations, :null => false   # Number of generations between the ancestor and the descendant. Parent/child = 1, for example.
    end

    # For "all progeny of…" and leaf selects:
    add_index :service_hierarchies, [:ancestor_id, :descendant_id, :generations],
      :unique => true, :name => "service_anc_desc_udx"

    # For "all ancestors of…" selects,
    add_index :service_hierarchies, [:descendant_id],
      :name => "service_desc_idx"
  end
end
