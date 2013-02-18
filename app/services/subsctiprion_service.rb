class SubscriptionService
  class << self
    def subscribe(user, action, target, subtarget = nil)
      Gitlab::Event::Subscription.subscribe(user, action, target, subtarget)
    end

    def available_subscriptions(user, target = nil)
      Gitlab::Event::Subscription.available(user, target)
    end
  end
end
