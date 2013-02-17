class ChangeColumnTypeForEventAction < ActiveRecord::Migration
  def up
    change_column :event_subscriptions, :action, :integer
    change_column :events, :action, :integer
  end

  def down
    change_column :event_subscriptions, :action, :string
    change_column :events, :action, :string
  end
end
