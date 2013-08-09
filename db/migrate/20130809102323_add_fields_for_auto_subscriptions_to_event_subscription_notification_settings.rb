class AddFieldsForAutoSubscriptionsToEventSubscriptionNotificationSettings < ActiveRecord::Migration
  def change
    add_column :event_subscription_notification_settings, :subscribe_if_owner, :boolean
    add_column :event_subscription_notification_settings, :subscribe_if_developer, :boolean
  end
end
