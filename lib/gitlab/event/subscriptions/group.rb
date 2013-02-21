module Gitlab
  module Event
    module Subscriptions
      class Group < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::Group

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
    end
  end
end
