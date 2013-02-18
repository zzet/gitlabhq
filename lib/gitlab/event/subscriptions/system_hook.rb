module Gitlab
  module Event
    module Subscriptions
      class SystemHook < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::SystemHook

        class << self
        end

      end
    end
  end
end
