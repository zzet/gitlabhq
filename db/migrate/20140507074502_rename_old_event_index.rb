class RenameOldEventIndex < ActiveRecord::Migration
  def change
    rename_index :old_events, 'index_events_on_action', 'index_old_events_on_action'
    rename_index :old_events, 'index_events_on_author_id', 'index_old_events_on_author_id'
    rename_index :old_events, 'index_events_on_created_at', 'index_old_events_on_created_at'
    rename_index :old_events, 'index_events_on_project_id', 'index_old_events_on_project_id'
    rename_index :old_events, 'index_events_on_target_id', 'index_old_events_on_target_id'
    rename_index :old_events, 'index_events_on_target_type', 'index_old_events_on_target_type'
  end
end
