module Gitlab
  module Event
    module Subscriptions
      class UserTeamUserRelationship < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::UserTeamUserRelationship

        class << self
        end

      end
    end
  end
end
