class AddSubscriberToNotifications < ActiveRecord::Migration
  def change
    add_column :event_subscription_notifications, :subscriber_id, :integer
  end
end
