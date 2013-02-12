class Subscription < ActiveRecord::Base
  attr_accessible :action, :last_notified_at, :notification_interval, :target_id, :target_type, :user_id

  belongs_to :user
  belongs_to :target, polymorphic: true

  validates :user, presence: true
  validates :target, presence: true
end
