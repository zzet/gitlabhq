module Gitlab
  module Event
    module Notification
      class Key < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::Key

        class << self
        end

      end
    end
  end
end
