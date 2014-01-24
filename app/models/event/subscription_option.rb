class Event::SubscriptionOption < ActiveRecord::Base
  attr_accessible :source, :subscription_id

  belongs_to :subscription, class_name: Event::Subscription

  validates :subscription, presence: true
  validates :source,       presence: true, uniqueness: { scope: :subscription_id }
end
