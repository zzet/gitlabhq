class AddIndexToEventSubscriptionNotificationsWithSubscriberId < ActiveRecord::Migration
  def change
    add_index(:event_subscription_notifications, [:event_id, :subscriber_id],
              name: 'for_notifications_event_id_subscriber_id')

    add_index(:event_subscription_notifications, :notification_state)

  end
end
