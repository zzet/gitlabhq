class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :event_subscription_notifications do |t|
      t.integer :event_id
      t.integer :subscription_id
      t.string :notification_state
      t.datetime :notified_at

      t.timestamps
    end
  end
end
