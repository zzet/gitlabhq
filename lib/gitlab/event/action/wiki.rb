module Gitlab
  module Event
    module Action
      module Wiki
        extend ActiveSupport::Concern
        include Gitlab::Event::Action::Base

        included do
          class << self
            def avaliable_actions(user = nil, source = nil)
              base_actions = [
                :created,
                :closed,
                :reopened,
                :deleted,
                :updated
              ]
            end
          end
        end

      end
    end
  end
end
