class Gitlab::Event::Subscription::Issue < Gitlab::Event::Subscription::Base
  class << self
    def can_subscribe?(user, action, target, source)
      return true
    end
  end

end
