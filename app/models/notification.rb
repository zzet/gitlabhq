class Notification < ActiveRecord::Base
  attr_accessible :event_id, :notification_state, :notified_at, :subscription_id

  belongs_to :event
  belongs_to :subscription

  def subscriber
    subscription.user
  end

  state_machine :notification_state, initial: :new do
    state :new
    state :processing
    state :delivered
    state :failed

    event :process do
      transition [:new] => :processing
    end

    event :deliver do
      transition [:processing] => :delivered
    end

    event :fail do
      transition [:processing] => :failed
    end
  end

end
