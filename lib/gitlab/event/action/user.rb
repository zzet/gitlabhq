module Gitlab
  module Event
    module Action
      module User
        extend ActiveSupport::Concern
        include Gitlab::Event::Action::Base

        included do
          class << self
            def avaliable_actions(user = nil, source = nil)
              base_actions = [
                :created,  # +
                :deleted,  # +
                :updated,  # +
                :joined,   # - # Join to ptoject or team
                :left,     # - # Left from project or team
                :transfer, # - # Change permission on team or project
                :added     # - # Add admin permission
              ]
            end
          end
        end

      end
    end
  end
end
