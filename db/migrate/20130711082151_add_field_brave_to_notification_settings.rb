class AddFieldBraveToNotificationSettings < ActiveRecord::Migration
  def change
    add_column :event_subscription_notification_settings, :brave, :boolean
  end
end
