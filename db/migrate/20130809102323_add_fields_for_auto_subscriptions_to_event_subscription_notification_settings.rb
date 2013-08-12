class AddFieldsForAutoSubscriptionsToEventSubscriptionNotificationSettings < ActiveRecord::Migration
  def change
    add_column :event_subscription_notification_settings, :subscribe_if_owner, :boolean, default: true
    add_column :event_subscription_notification_settings, :subscribe_if_developer, :boolean, default: true
  end
end
