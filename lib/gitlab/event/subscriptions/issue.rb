class Gitlab::Event::Subscription::Issue < Gitlab::Event::Subscriptions::Base
  class << self
    def can_subscribe?(user, action, target, source)
      return true
    end
  end

end
