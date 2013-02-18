module Gitlab
  module Event
    module Notification
      class ProjectHook < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::ProjectHook

        class << self
        end

      end
    end
  end
end
