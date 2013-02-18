module Gitlab
  module Event
    module Notification
      class Wiki < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::Wiki

        class << self
        end

      end
    end
  end
end
