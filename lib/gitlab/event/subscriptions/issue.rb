module Gitlab
  module Event
    module Subscriptions
      class Issue < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::Issue

        class << self
        end

      end
    end
  end
end
