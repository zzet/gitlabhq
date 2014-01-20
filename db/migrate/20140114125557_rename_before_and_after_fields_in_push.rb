class RenameBeforeAndAfterFieldsInPush < ActiveRecord::Migration
  def change
    rename_column :pushes, :before, :revbefore
    rename_column :pushes, :after,  :revafter
  end
end
