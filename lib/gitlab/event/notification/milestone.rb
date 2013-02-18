module Gitlab
  module Event
    module Notification
      class Milestone < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::Milestone

        class << self
        end

      end
    end
  end
end
