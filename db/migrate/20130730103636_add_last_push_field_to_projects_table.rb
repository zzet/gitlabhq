class AddLastPushFieldToProjectsTable < ActiveRecord::Migration
  def up
    add_column :projects, :last_pushed_at, :datetime
    add_index :projects, :last_pushed_at

    Project.find_each do |project|
      last_push_date = if project.last_push
                         project.related_events.where(action: [:pushed, :craeted_branch, :created_tag, :deleted_branch, :deleted_tag]).last.created_at
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
