class MoveDataConvertGroupToNamespace < ActiveRecord::Migration
  def up
    Namespace.update_all(type: 'Group')
  end

  def down
    raise 'Rollback is not allowed'
  end
end
