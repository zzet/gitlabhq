module Gitlab
  module Event
    module Subscriptions
      class Project < Gitlab::Event::Subscriptions::Base
        include Gitlab::Event::Action::Project

        class << self
        end

      end
    end
  end
end
