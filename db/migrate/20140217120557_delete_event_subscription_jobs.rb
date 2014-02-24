class DeleteEventSubscriptionJobs < ActiveRecord::Migration
  def change
    drop_table :event_subscription_jobs
  end
end
