class EventsToOldEvents < ActiveRecord::Migration
  def change
    rename_table :events, :old_events
  end
end
