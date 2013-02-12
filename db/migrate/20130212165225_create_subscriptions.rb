class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer :user_id
      t.string :action
      t.integer :target_id
      t.string :target_type
      t.integer :notification_interval
      t.datetime :last_notified_at

      t.timestamps
    end
  end
end
