module Gitlab
  module Event
    module Subscriptions
      class Key < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::Key

        class << self
        end

      end
    end
  end
end
