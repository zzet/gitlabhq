class Event::Subscription::NotificationSetting < ActiveRecord::Base
  attr_accessible :own_changes, :adjacent_changes, :user_id

  belongs_to :user
end
