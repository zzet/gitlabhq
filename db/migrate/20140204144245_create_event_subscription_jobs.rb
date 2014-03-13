class CreateEventSubscriptionJobs < ActiveRecord::Migration
  def change
    create_table :event_subscription_jobs do |t|
      t.string :subscription_type
      t.references :user, index: true
      t.string :state

      t.timestamps
    end
  end
end
