module Gitlab
  module Event
    module Subscriptions
      class MergeRequest < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::MergeRequest

        class << self
        end

      end
    end
  end
end
