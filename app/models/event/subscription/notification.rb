class Event::Subscription::Notification < ActiveRecord::Base
  attr_accessible :event_id, :event, :notification_state, :notified_at, :subscription_id

  belongs_to :event
  belongs_to :subscription, class_name: Event::Subscription

  validates :event,        presence: true
  validates :subscription, presence: true

  scope :pending, -> { where(notification_state: :new) }
  scope :instantaneous, -> { pending.where(notification_interval: 0) }

  def subscriber
    subscription.user
  end

  state_machine :notification_state, initial: :new do
    state :new
    state :processing
    state :delivered
    state :failed

    event :process do
      transition [:new, :failed] => :processing
    end

    event :deliver do
      transition [:processing] => :delivered
    end

    event :failing do
      transition [:processing] => :failed
    end
  end

end
