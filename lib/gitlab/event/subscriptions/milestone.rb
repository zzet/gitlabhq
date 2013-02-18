module Gitlab
  module Event
    module Subscriptions
      class Milestone < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::Milestone

        class << self
        end

      end
    end
  end
end
