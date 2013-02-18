module Gitlab
  module Event
    module Action
      module UserTeam
        extend ActiveSupport::Concern
        include Gitlab::Event::Action::Base

        included do
          class << self
            def avaliable_actions(user = nil, source = nil)
              base_actions = [
                :created,
                :deleted,
                :updated,
                :assigned,
                :reassigned,
                :transfer
              ]
            end
          end
        end

      end
    end
  end
end
