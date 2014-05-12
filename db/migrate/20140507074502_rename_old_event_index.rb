class RenameOldEventIndex < ActiveRecord::Migration
  def change

    if index_name_exists?(:old_events, 'index_events_on_action', false)
      rename_index :old_events, 'index_events_on_action', 'index_old_events_on_action'
    end

    if index_name_exists?(:old_events, 'index_events_on_author_id', false)
      rename_index :old_events, 'index_events_on_author_id', 'index_old_events_on_author_id'
    end

    if index_name_exists?(:old_events, 'index_events_on_created_at', false)
      rename_index :old_events, 'index_events_on_created_at', 'index_old_events_on_created_at'
    end

    if index_name_exists?(:old_events, 'index_events_on_project_id', false)
      rename_index :old_events, 'index_events_on_project_id', 'index_old_events_on_project_id'
    end

    if index_name_exists?(:old_events, 'index_events_on_target_id', false)
      rename_index :old_events, 'index_events_on_target_id', 'index_old_events_on_target_id'
    end

    if index_name_exists?(:old_events, 'index_events_on_target_type', false)
      rename_index :old_events, 'index_events_on_target_type', 'index_old_events_on_target_type'
    end

  end
end
