module Gitlab
  module Event
    module Notification
      class User < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::User

        class << self
        end

      end
    end
  end
end
