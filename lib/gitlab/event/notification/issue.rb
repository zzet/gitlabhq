module Gitlab
  module Event
    module Notification
      class Issue < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::Issue

        class << self
        end

      end
    end
  end
end
