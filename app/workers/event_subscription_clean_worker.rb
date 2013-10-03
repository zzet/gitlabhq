class EventSubscriptionCleanWorker
  def self.call(name, started, finished, unique_id, data)

    gitlab, action, source = name.split "."

    begin
      # TODO. Check, if need to destroy subscriptions while user transfer prject between groups, for example
      # If User subscribed to ptoject while assigned team or group (!!!)
      if (Event::Subscription.global_entity_to_subscription.include? source.to_sym) && ([:deleted].include? action.to_sym)
        Event::Subscription.by_target(data[:source]).each do |subscription|
          Sidekiq::Client.enqueue_to(:mail_notifications, EventSubscriptionCleanWorker, subscription.id)
        end
      end
    rescue
      Rails.logger.warn "Error while process destroy subscription on action #{name}"
    end
  end

  include Sidekiq::Worker

  sidekiq_options queue: :mail_notifications

  def perform(subscription_id)
    subscription = Event::Subscription.find_by_id(subscription_id)
    if subscription
      if Event::Subscription::Notification.where(subscription_id: subscription, notification_state: [:new, :delayed]).any?
        Sidekiq::Client.enqueue_to(:mail_notifications, EventSubscriptionCleanWorker, subscription_id)
      else
        subscription.destroy
      end
    end
  end
end
