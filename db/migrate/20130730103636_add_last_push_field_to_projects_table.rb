class AddLastPushFieldToProjectsTable < ActiveRecord::Migration
  def up
    add_column :projects, :last_pushed_at, :datetime
    add_index :projects, :last_pushed_at

    Project.find_each do |project|
      last_push_date = if project.last_push
                         project.old_events.where(action: 5).last.created_at
                       else
                         project.created_at
                       end
      project.update_attribute(:last_pushed_at, last_push_date)
    end
  end

  def down
    remove_index :projects, :last_pushed_at
    remove_column :projects, :last_pushed_at
  end
end
