module Gitlab
  module Event
    module Subscriptions
      class UserTeam < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::UserTeam

        class << self
        end

      end
    end
  end
end
