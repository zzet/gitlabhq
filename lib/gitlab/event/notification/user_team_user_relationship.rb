module Gitlab
  module Event
    module Notification
      class UserTeamUserRelationship < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::UserTeamUserRelationship

        class << self
        end

      end
    end
  end
end
