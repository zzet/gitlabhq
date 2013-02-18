module Gitlab
  module Event
    module Subscriptions
      class UserTeamProjectRelationship < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::UserTeamProjectRelationship

        class << self
        end

      end
    end
  end
end
