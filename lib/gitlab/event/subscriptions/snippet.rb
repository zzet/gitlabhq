module Gitlab
  module Event
    module Subscriptions
      class Snippet < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::Snippet

        class << self
        end

      end
    end
  end
end
