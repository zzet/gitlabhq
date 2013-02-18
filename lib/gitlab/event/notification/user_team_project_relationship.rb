module Gitlab
  module Event
    module Notification
      class UserTeamProjectRelationship < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::UserTeamProjectRelationship

        class << self
        end

      end
    end
  end
end
