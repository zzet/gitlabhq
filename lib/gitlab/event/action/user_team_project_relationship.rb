module Gitlab
  module Event
    module Action
      module UserTeamProjectRelationship
        extend ActiveSupport::Concern
        include Gitlab::Event::Action::Base

        included do
          class << self
            def avaliable_actions(user = nil, source = nil)
              # Review
              base_actions = [
                :created,
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
