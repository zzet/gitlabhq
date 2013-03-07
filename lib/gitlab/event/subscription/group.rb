class Gitlab::Event::Subscription::Group < Gitlab::Event::Subscription::Base
  class << self
    def can_subscribe?(user, action, target, source)
      if target.is_a? ::Group
        return true if user.is_admin?
        return true if target.owner == user
        return false
      end
    end
  end

end
