class AddAdjacentChangesFieldToEventNotificationSettings < ActiveRecord::Migration
  def change
    add_column :event_subscription_notification_settings, :adjacent_changes, :boolean
  end
end
