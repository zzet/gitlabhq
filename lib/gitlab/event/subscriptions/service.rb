module Gitlab
  module Event
    module Subscriptions
      class Service < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::Service

        class << self
        end

      end
    end
  end
end
