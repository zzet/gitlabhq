module Gitlab
  module Event
    module Subscriptions
      class Issue < Gitlab::Event::Subscriptions::Base
        class << self
          def can_subscribe?(user, action, target, source)
            return true
          end
        end

      end
    end
  end
end
