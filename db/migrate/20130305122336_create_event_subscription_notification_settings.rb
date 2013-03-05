class CreateEventSubscriptionNotificationSettings < ActiveRecord::Migration
  def change
    create_table :event_subscription_notification_settings do |t|
      t.integer :user_id
      t.boolean :own_changes

      t.timestamps
    end
  end
end
