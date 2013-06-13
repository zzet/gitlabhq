class AddParentEventIdFieldToEventsTable < ActiveRecord::Migration
  def change
    add_column :events, :parent_event_id, :integer
  end
end
