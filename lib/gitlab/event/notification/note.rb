module Gitlab
  module Event
    module Notification
      class Note < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::Note

        class << self
        end

      end
    end
  end
end
