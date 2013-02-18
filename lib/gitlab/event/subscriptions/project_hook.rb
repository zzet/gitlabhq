module Gitlab
  module Event
    module Subscriptions
      class ProjectHook < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::ProjectHook

        class << self
        end

      end
    end
  end
end
