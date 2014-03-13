class AddLinkToAutoSubscriptionFromEventSubscription < ActiveRecord::Migration
  def change
    add_column :event_subscriptions, :auto_subscription_id, :integer
  end
end
