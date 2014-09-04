class EventSubscriptionDestroyWorker
  def self.call(name, started, finished, unique_id, data)

    _, action, _ = name.split "."

    begin
      # TODO. Check, if need to destroy subscriptions while user transfer prject between groups, for example
      # If User subscribed to ptoject while assigned team or group (!!!)
      if [:deleted].include?(action.to_sym)
        Event::Subscription.by_target(data[:source]).each do |subscription|
          Resque.enqueue(EventSubscriptionDestroyWorker, subscription.id)
        end
      end
    rescue
      Rails.logger.warn "Error while process destroy subscription on action #{name}"
    end
  end

  @queue = :mail_notifications

  def self.perform(subscription_id)
    subscription = Event::Subscription.find_by(id: subscription_id)
    if subscription
      if Event::Subscription::Notification.where(subscription_id: subscription, notification_state: [:new, :delayed]).any?
        Resque.enqueue(EventSubscriptionDestroyWorker, subscription_id)
      else
        subscription.destroy
      end
    end
  end
end
