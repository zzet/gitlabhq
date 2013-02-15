module Gitlab
  module Event
    module Builder
      class UserTeamProjectRelationship < Gitlab::Event::Builder::Base
        # Review
        @avaliable_action = [:created,
                             :deleted,
                             :updated
                            ]

        class << self
          def can_build?(action, data)
            known_action = known_action? @avaliable_action, action
            known_target = data.is_a? ::UserTeamProjectRelationship
            known_target && known_action
          end

          def build(data)
          end
        end
      end
    end
  end
end
