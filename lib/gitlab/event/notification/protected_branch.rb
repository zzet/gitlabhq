module Gitlab
  module Event
    module Notification
      class ProtectedBranch < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::ProtectedBranch

        class << self
        end

      end
    end
  end
end
