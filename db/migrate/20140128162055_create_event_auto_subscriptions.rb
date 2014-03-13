class CreateEventAutoSubscriptions < ActiveRecord::Migration
  def change
    create_table :event_auto_subscriptions do |t|
      t.integer :user_id
      t.string :target
      t.integer :namespace_id
      t.string :namespace_type

      t.timestamps
    end
  end
end
