class SubscriptionService
  class << self
    def subscribe(user, action, target, source = nil)
      Gitlab::Event::Subscription.subscribe(user, action, target, source)
    end

    def unsubscribe(user, action, target, source = nil)
      Gitlab::Event::Subscription.unsubscribe(user, action, target, source)
    end

    def available_subscriptions(user, source = nil)
      Gitlab::Event::Subscription.available(user, source)
    end
  end
end
