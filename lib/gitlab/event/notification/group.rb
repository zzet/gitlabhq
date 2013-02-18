module Gitlab
  module Event
    module Notification
      class Group < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::Group

        class << self
        end

      end
    end
  end
end
