module Gitlab
  module Event
    module Subscriptions
      class User < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::User

        class << self
        end

      end
    end
  end
end
