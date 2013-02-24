class ConvertGroupToNamespace < ActiveRecord::Migration
  def up
    rename_table 'groups', 'namespaces'
    add_column :namespaces, :type, :string, null: true
  end

  def down
    raise 'Rollback is not allowed'
  end
end
