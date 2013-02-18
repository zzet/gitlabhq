class SubscriptionService
  class << self
    def subscribe!(user, action, target)
      user.subscriptions.create(action: action, target: target)
    end
  end
end
