module Gitlab
  module Event
    module Subscriptions
      class Note < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::Note

        class << self
        end

      end
    end
  end
end
