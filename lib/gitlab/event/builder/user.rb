module Gitlab
  module Event
    module Builder
      class User < Gitlab::Event::Builder::Base
        @avaliable_action = [:created,
                             :deleted,
                             :updated,
                             :joined,   # Join to ptoject or team
                             :left,     # Left from project or team
                             :transfer, # Change permission on team or project
                             :added     # Add admin permission
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            known_target = data.is_a? ::User
            known_target && known_action
          end

          def build(data)
          end
        end
      end
    end
  end
end
