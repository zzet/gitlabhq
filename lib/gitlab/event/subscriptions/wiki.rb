module Gitlab
  module Event
    module Subscriptions
      class Wiki < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::Wiki

        class << self
        end

      end
    end
  end
end
