module Gitlab
  module Event
    module Subscriptions
      class ProtectedBranch < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::ProtectedBranch

        class << self
        end

      end
    end
  end
end
