class AddSystemNotificationsToEventSubscriptionNotificationSetting < ActiveRecord::Migration
  def change
    add_column :event_subscription_notification_settings, :system_notifications, :boolean
  end
end
