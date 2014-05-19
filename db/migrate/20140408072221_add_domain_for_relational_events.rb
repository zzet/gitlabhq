class AddDomainForRelationalEvents < ActiveRecord::Migration
  def change
    add_column :events, :first_domain_id, :integer
    add_column :events, :first_domain_type, :string

    add_column :events, :second_domain_id, :integer
    add_column :events, :second_domain_type, :string
  end
end
