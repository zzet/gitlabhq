module Gitlab
  module Event
    module Notification
      class Snippet < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::Snippet

        class << self
        end

      end
    end
  end
end
