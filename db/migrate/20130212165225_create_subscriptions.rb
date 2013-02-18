class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :event_subscriptions do |t|
      t.integer :user_id
      t.integer :action
      t.integer :target_id
      t.string :target_type
      t.integer :source_id
      t.string :source_type
      t.string :source_category
      t.integer :notification_interval
      t.datetime :last_notified_at

      t.timestamps
    end
  end
end
