class AddIndexToEvents < ActiveRecord::Migration
  def change
    add_index(:events, :parent_event_id)
  end
end
