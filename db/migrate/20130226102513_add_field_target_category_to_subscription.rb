class AddFieldTargetCategoryToSubscription < ActiveRecord::Migration
  def change
    add_column :event_subscriptions, :target_category, :string
  end
end
