class Notification < ActiveRecord::Base
  attr_accessible :event_id, :notification_state, :notified_at, :subscription_id
end
