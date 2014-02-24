class CreateEventSubscriptionOptions < ActiveRecord::Migration
  def change
    create_table :event_subscription_options do |t|
      t.integer :subscription_id
      t.string :source

      t.timestamps
    end
  end
end
