module Gitlab
  module Event
    module Subscriptions
      class UsersProject < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::UsersProject

        class << self
        end

      end
    end
  end
end
