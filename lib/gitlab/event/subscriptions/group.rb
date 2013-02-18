module Gitlab
  module Event
    module Subscriptions
      class Group < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::Group

        class << self
        end

      end
    end
  end
end
