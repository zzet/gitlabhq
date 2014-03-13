class AddOptionsArrayToSubscriptions < ActiveRecord::Migration
  def change
    add_column :event_subscriptions, :options, :string, array: true, default: '{}', using: 'gin'
  end
end
