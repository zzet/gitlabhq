module Gitlab
  module Event
    module Notification
      class MergeRequest < Gitlab::Event::Notification::Base
        include Gitlab::Event::Action::MergeRequest

        class << self
        end

      end
    end
  end
end
